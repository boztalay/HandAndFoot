import abc
import enum
import json
import random
import sys

#
# Errors
#

class IllegalActionError(Exception):
    pass

class IllegalSetupError(Exception):
    pass

#
# Cards, Decks
#

class CardSuit(enum.Enum):
    HEARTS = "hearts"
    DIAMONDS = "diamonds"
    CLUBS = "clubs"
    SPADES = "spades"

    @property
    def is_red(self):
        return ((self == CardSuit.HEARTS) or (self == CardSuit.DIAMONDS))

class CardRank(enum.Enum):
    TWO = "two"
    THREE = "three"
    FOUR = "four"
    FIVE = "five"
    SIX = "six"
    SEVEN = "seven"
    EIGHT = "eight"
    NINE = "nine"
    TEN = "ten"
    JACK = "jack"
    QUEEN = "queen"
    KING = "king"
    ACE = "ace"
    JOKER = "joker"

class Card(object):

    @staticmethod
    def from_json(card_json):
        return Card(CardSuit(card_json["suit"]), CardRank(card_json["rank"]))

    def __init__(self, suit, rank):
        self.suit = suit
        self.rank = rank

    @property
    def is_wild(self):
        return ((self.rank == CardRank.TWO) or (self.rank == CardRank.JOKER))

    @property
    def can_start_book(self):
        return ((not self.is_wild) and (self.rank != CardRank.THREE))

    @property
    def point_value(self):
        if self.rank in [CardRank.TWO]:
            return 20
        elif self.rank in [CardRank.THREE]:
            if self.suit.is_red:
                return -100
            else:
                return 0
        elif self.rank in [CardRank.FOUR, CardRank.FIVE, CardRank.SIX, CardRank.SEVEN, CardRank.EIGHT]:
            return 5
        elif self.rank in [CardRank.NINE, CardRank.TEN, CardRank.JACK, CardRank.QUEEN, CardRank.KING]:
            return 10
        elif self.rank in [CardRank.ACE]:
            return 20
        elif self.rank in [CardRank.JOKER]:
            return 50
        else:
            raise ValueError("Unknown rank: %s" % self.rank)

    def __eq__(self, other):
        return ((self.suit == other.suit) and (self.rank == other.rank))

    def __str__(self):
        return "<Card (%s, %s)>" % (self.rank, self.suit)

    def to_json(self):
        return {
            "suit": self.suit.value,
            "rank": self.rank.value
        }

class Deck(object):

    @staticmethod
    def from_json(deck_json):
        deck = Deck()

        for card_json in deck_json["cards"]:
            deck.cards.append(Card.from_json(card_json))

        return deck

    def __init__(self, standard_deck_count=None):
        self.cards = []

        if standard_deck_count is not None:
            for _ in range(0, standard_deck_count):
                for suit in CardSuit:
                    for rank in CardRank:
                        if rank != CardRank.JOKER:
                            self.cards.append(Card(suit, rank))

                self.cards.append(Card(CardSuit.SPADES, CardRank.JOKER))
                self.cards.append(Card(CardSuit.SPADES, CardRank.JOKER))

    @property
    def is_empty(self):
        return (self.card_count == 0)

    @property
    def card_count(self):
        return len(self.cards)

    def shuffle(self):
        random.shuffle(self.cards)

    def draw(self):
        if self.is_empty:
            return None
        else:
            return self.cards.pop()

    def replenish_cards_and_shuffle(self, cards):
        self.cards = cards
        self.shuffle()

    def to_json(self):
        return {
            "cards": [card.to_json() for card in self.cards]
        }

#
# Book
#

class Book(object):

    def __init__(self, initial_cards):
        if len(initial_cards) < 3:
            raise IllegalActionError("Not enough cards to start a book")

        if len([card for card in initial_cards if card.can_start_book]) == 0:
            raise IllegalActionError("Cannot start a book with the given cards")

        for card in initial_cards:
            if card.can_start_book:
                self.rank = card.rank
                break

        self.cards = []

        for card in [card for card in initial_cards if not card.is_wild]:
            self.add_card(card)

        for card in [card for card in initial_cards if card.is_wild]:
            self.add_card(card)

    @property
    def card_count(self):
        return len(self.cards)

    @property
    def wild_count(self):
        return len([card for card in self.cards if card.is_wild])

    @property
    def natural_count(self):
        return len([card for card in self.cards if not card.is_wild])

    @property
    def is_natural(self):
        return (self.wild_count == 0)

    @property
    def is_complete(self):
        return (len(self.cards) >= 7)

    @property
    def cards_value(self):
        return sum([card.point_value for card in self.cards])

    @property
    def book_value(self):
        if not self.is_complete:
            return 0

        if self.is_natural:
            return 500
        else:
            return 300

    def add_card(self, card):
        if card.is_wild:
            self.add_wild_card(card)
        else:
            self.add_natural_card(card)

    def add_wild_card(self, card):
        if self.wild_count >= (self.natural_count - 1):
            raise IllegalActionError("Too many wilds in book to add another")

        self.cards.append(card)

    def add_natural_card(self, card):
        if card.rank != self.rank:
            raise IllegalActionError("Card doesn't match book rank")

        self.cards.append(card)

    def to_json(self):
        return {
            "rank": self.rank.value,
            "cards": [card.to_json() for card in self.cards]
        }

#
# Round
#

class Round(enum.Enum):
    NINETY = "ninety"
    ONE_TWENTY = "one_twenty"
    ONE_FIFTY = "one_fifty"
    ONE_EIGHTY = "one_eighty"

    @property
    def points_needed(self):
        if self == Round.NINETY:
            return 90
        elif self == Round.ONE_TWENTY:
            return 120
        elif self == Round.ONE_FIFTY:
            return 150
        elif self == Round.ONE_EIGHTY:
            return 180
        else:
            raise ValueError("Unknown round")

    @property
    def next_round(self):
        if self == Round.NINETY:
            return Round.ONE_TWENTY
        elif self == Round.ONE_TWENTY:
            return Round.ONE_FIFTY
        elif self == Round.ONE_FIFTY:
            return Round.ONE_EIGHTY
        elif self == Round.ONE_EIGHTY:
            return None
        else:
            raise ValueError("Unknown round")

#
# Player
#

class Points(object):

    def __init__(self):
        self.in_hand = 0
        self.in_foot = 0
        self.in_books = 0
        self.laid_down = 0
        self.for_going_out = 0

    def to_json(self):
        return {
            "in_hand": self.in_hand,
            "in_foot": self.in_foot,
            "in_books": self.in_books,
            "laid_down": self.laid_down,
            "for_going_out": self.for_going_out
        }

class Player(object):

    def __init__(self, name):
        self.name = name
        self.hand = []
        self.foot = []

        self.books = {
            Round.NINETY: {},
            Round.ONE_TWENTY: {},
            Round.ONE_FIFTY: {},
            Round.ONE_EIGHTY: {}
        }

        self.points = {
            Round.NINETY: Points(),
            Round.ONE_TWENTY: Points(),
            Round.ONE_FIFTY: Points(),
            Round.ONE_EIGHTY: Points()
        }

        self.cards_drawn_from_deck = 0
        self.cards_drawn_from_discard_pile = 0
        self.has_laid_down_this_round = False

    def set_hand_and_foot(self, hand, foot):
        if len(hand) != 13 or len(foot) != 13:
            raise IllegalSetupError("Initial hand or foot not sized correctly")

        self.hand = hand
        self.foot = foot

    @property
    def can_draw_from_deck(self):
        return ((self.cards_drawn_from_deck + self.cards_drawn_from_discard_pile) < 2)

    @property
    def can_draw_from_discard_pile(self):
        return ((self.cards_drawn_from_deck < 2) and (self.cards_drawn_from_discard_pile < 1))

    @property
    def is_hand_empty(self):
        return (len(self.hand) == 0)

    @property
    def is_in_foot(self):
        return (len(self.foot) == 0)

    @property
    def can_end_turn(self):
        return ((self.cards_drawn_from_deck + self.cards_drawn_from_discard_pile) == 2)

    def can_go_out(self, current_round):
        return (self.has_natural_book(current_round) and self.has_unnatural_book(current_round) and self.is_in_foot)

    def has_natural_book(self, current_round):
        return (len([book for book in self.books[current_round].values() if book.is_natural]) > 0)

    def has_unnatural_book(self, current_round):
        return (len([book for book in self.books[current_round].values() if not book.is_natural]) > 0)

    def add_card_to_hand_from_deck(self, card):
        self.hand.append(card)
        self.cards_drawn_from_deck += 1

    def add_card_to_hand_from_discard_pile(self, card):
        self.hand.append(card)
        self.cards_drawn_from_discard_pile += 1

    def remove_card_from_hand(self, card):
        try:
            self.hand.remove(card)
        except ValueError:
            raise IllegalActionError("Card not in hand")

    def add_cards_from_hand_to_book(self, cards, book_rank, current_round):
        if book_rank not in self.books[current_round]:
            raise IllegalActionError("Player doesn't have a book for the given card")

        for card in cards:
            self.remove_card_from_hand(card)
            self.books[current_round][book_rank].add_card(card)

    def add_card_from_discard_pile_to_book(self, card, book_rank, current_round):
        if book_rank not in self.books[current_round]:
            raise IllegalActionError("Player doesn't have a book for the given card")

        self.books[current_round][book_rank].add_card(card)
        self.cards_drawn_from_discard_pile += 1

    def start_book(self, cards, current_round):
        book = Book(cards)

        if book.rank in self.books[current_round]:
            raise IllegalActionError("Player already has a book of the given rank")

        for card in cards:
            self.remove_card_from_hand(card)

        self.books[current_round][book.rank] = book

    def laid_down(self):
        self.has_laid_down_this_round = True

    def pick_up_foot(self):
        self.hand = self.foot
        self.foot = []

    def turn_ended(self):
        self.cards_drawn_from_deck = 0
        self.cards_drawn_from_discard_pile = 0

    def round_ended(self):
        self.turn_ended()
        self.has_laid_down_this_round = False

    def calculate_points(self, current_round):
        self.points[current_round].in_hand = sum([(-card.point_value if card.point_value > 0 else card.point_value) for card in self.hand])
        self.points[current_round].in_foot = sum([(-card.point_value if card.point_value > 0 else card.point_value) for card in self.foot])
        self.points[current_round].in_books = sum([book.book_value for book in self.books[current_round].values()])
        self.points[current_round].laid_down = sum([book.cards_value for book in self.books[current_round].values()])

    def add_bonus_for_going_out(self, current_round):
        self.points[current_round].for_going_out = 100

    def to_json(self):
        books_json = {}
        for (current_round, round_books) in self.books.items():
            books_json[current_round.value] = {}
            for (rank, book) in round_books.items():
                books_json[current_round.value][rank.value] = book.to_json()

        points_json = {}
        for (points_round, points) in self.points.items():
            points_json[points_round.value] = points.to_json()

        return {
            "name": self.name,
            "hand": [card.to_json() for card in self.hand],
            "foot": [card.to_json() for card in self.foot],
            "books": books_json,
            "points": points_json
        }

#
# Actions
#

class Action(abc.ABC):

    @staticmethod
    def from_json(action_json):
        action_type = action_json["type"]

        if action_type == "draw_from_deck":
            return DrawFromDeckAction(action_json["player"])
        elif action_type == "draw_from_discard_pile_and_add_to_book":
            book_rank = CardRank(action_json["book_rank"])
            return DrawFromDiscardPileAndAddToBookAction(action_json["player"], book_rank)
        elif action_type == "draw_from_discard_pile_and_start_book":
            cards = [Card.from_json(card_json) for card_json in action_json["cards"]]
            return DrawFromDiscardPileAndStartBookAction(action_json["player"], cards)
        elif action_type == "discard_card":
            card = Card.from_json(action_json["card"])
            return DiscardCardAction(action_json["player"], card)
        elif action_type == "lay_down_initial_books":
            books = [[Card.from_json(card_json) for card_json in cards_json] for cards_json in action_json["books"]]
            return LayDownInitialBooksAction(action_json["player"], books)
        elif action_type == "draw_from_discard_pile_and_lay_down_initial_books":
            partial_book = [Card.from_json(card_json) for card_json in action_json["partial_book"]]
            books = [[Card.from_json(card_json) for card_json in cards_json] for cards_json in action_json["books"]]
            return DrawFromDiscardPileAndLayDownInitialBooksAction(action_json["player"], partial_book, books)
        elif action_type == "start_book":
            cards = [Card.from_json(card_json) for card_json in action_json["cards"]]
            return StartBookAction(action_json["player"], cards)
        elif action_type == "add_cards_from_hand_to_book":
            cards = [Card.from_json(card_json) for card_json in action_json["cards"]]
            book_rank = CardRank(action_json["book_rank"])
            return AddCardsFromHandToBookAction(action_json["player"], cards, book_rank)
        else:
            raise ValueError("Unknown action type: " + action_type)

    def __init__(self, player_name):
        self.player_name = player_name

class DrawFromDeckAction(Action):
    def __init__(self, player_name):
        super().__init__(player_name)

class DrawFromDiscardPileAndAddToBookAction(Action):
    def __init__(self, player_name, book_rank):
        super().__init__(player_name)
        self.book_rank = book_rank

class DrawFromDiscardPileAndStartBookAction(Action):
    def __init__(self, player_name, cards):
        super().__init__(player_name)
        self.cards = cards

class DiscardCardAction(Action):
    def __init__(self, player_name, card):
        super().__init__(player_name)
        self.card = card

class LayDownInitialBooksAction(Action):
    def __init__(self, player_name, books):
        super().__init__(player_name)
        self.books = books

class DrawFromDiscardPileAndLayDownInitialBooksAction(Action):
    def __init__(self, player_name, partial_book, books):
        super().__init__(player_name)
        self.partial_book = partial_book
        self.books = books

class StartBookAction(Action):
    def __init__(self, player_name, cards):
        super().__init__(player_name)
        self.cards = cards

class AddCardsFromHandToBookAction(Action):
    def __init__(self, player_name, cards, book_rank):
        super().__init__(player_name)
        self.cards = cards
        self.book_rank = book_rank

#
# Game
#

class PlayerIterator(object):

    def __init__(self, players):
        self.players = players
        self.index = 0

    @property
    def current_player(self):
        return self.players[self.index]

    def go_to_next_player(self):
        self.index = (self.index + 1) % len(self.players)

    def is_current_player(self, player):
        return (player is self.current_player)

class Game(object):

    @property
    def deck(self):
        return self.decks[self.round]

    def __init__(self, player_names, decks):
        if len(player_names) < 2:
            raise IllegalSetupError("Not enough players")

        if len(player_names) > 6:
            raise IllegalSetupError("Too many players")

        self.decks = decks
        self.discard_pile = []
        self.round = Round.NINETY

        self.players = []
        for player_name in player_names:
            self.players.append(Player(player_name))

        self.player_iterator = PlayerIterator(self.players)

        for player in self.players:
            self.deal_cards_to_player(player)

        for player in self.players:
            player.calculate_points(self.round)

    def deal_cards_to_player(self, player):
        hand = []
        for _ in range(0, 13):
            hand.append(self.deck.draw())

        foot = []
        for _ in range(0, 13):
            foot.append(self.deck.draw())

        player.set_hand_and_foot(hand, foot)

    def apply_action(self, action):
        if self.round is None:
            raise IllegalActionError("Game is over")

        player = self.get_player_named(action.player_name)
        if player is None:
            raise IllegalActionError("Unknown player")

        if not self.player_iterator.is_current_player(player):
            raise IllegalActionError("Not your turn")

        if type(action) is DrawFromDeckAction:
            self.apply_draw_from_deck_action(player)
        elif type(action) is DrawFromDiscardPileAndAddToBookAction:
            self.apply_draw_from_discard_pile_and_add_to_book_action(player, action.book_rank)
        elif type(action) is DrawFromDiscardPileAndStartBookAction:
            self.apply_draw_from_discard_pile_and_start_book_action(player, action.cards)
        elif type(action) is DiscardCardAction:
            self.apply_discard_card_action(player, action.card)
        elif type(action) is LayDownInitialBooksAction:
            self.apply_lay_down_initial_books_action(player, action.books)
        elif type(action) is DrawFromDiscardPileAndLayDownInitialBooksAction:
            self.apply_draw_from_discard_pile_and_lay_down_initial_books_action(player, action.partial_book, action.books)
        elif type(action) is StartBookAction:
            self.apply_start_book_action(player, action.cards)
        elif type(action) is AddCardsFromHandToBookAction:
            self.apply_add_cards_from_hand_to_book_action(player, action.cards, action.book_rank)
        else:
            raise ValueError("Unknown action type")

        player.calculate_points(self.round)

    def get_player_named(self, player_name):
        for player in self.players:
            if player.name == player_name:
                return player

        return None

    def apply_draw_from_deck_action(self, player):
        if not player.can_draw_from_deck:
            raise IllegalActionError("Cannot draw from the deck")

        player.add_card_to_hand_from_deck(self.deck.draw())

        if self.deck.is_empty:
            self.deck.replenish_cards_and_shuffle(self.discard_pile)
            self.discard_pile = []

            if self.deck.is_empty:
                self.end_round_with_player_going_out(None)

    def apply_draw_from_discard_pile_and_add_to_book_action(self, player, book_rank):
        if not player.can_draw_from_discard_pile or not player.has_laid_down_this_round:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.discard_pile.pop()
        player.add_card_from_discard_pile_to_book(card, book_rank, self.round)

    def apply_draw_from_discard_pile_and_start_book_action(self, player, cards):
        if not player.can_draw_from_discard_pile:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.discard_pile.pop()
        cards.append(card)

        player.add_card_to_hand_from_discard_pile(card)
        player.start_book(cards, self.round)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_discard_card_action(self, player, card):
        if not player.can_end_turn:
            raise IllegalActionError("Cannot end turn yet")

        player.remove_card_from_hand(card)
        self.discard_pile.append(card)

        if player.is_hand_empty and player.is_in_foot:
            if not player.can_go_out(self.round):
                raise IllegalActionError("Cannot go out")

            self.end_round_with_player_going_out(player)
        else:
            if player.is_hand_empty:
                player.pick_up_foot()

            player.turn_ended()
            self.player_iterator.go_to_next_player()

    def apply_lay_down_initial_books_action(self, player, books_cards):
        if player.has_laid_down_this_round:
            raise IllegalActionError("Already laid down this round")

        books = [Book(book_cards) for book_cards in books_cards]
        points_in_books = sum([book.cards_value for book in books])

        if points_in_books < self.round.points_needed:
            raise IllegalActionError("Not enough points to lay down")

        for book_cards in books_cards:
            player.start_book(book_cards, self.round)

        player.laid_down()

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_draw_from_discard_pile_and_lay_down_initial_books_action(self, player, partial_book_cards, books_cards):
        if player.has_laid_down_this_round:
            raise IllegalActionError("Already laid down this round")

        if not player.can_draw_from_discard_pile:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.discard_pile.pop()
        complete_partial_book = partial_book_cards + [card]
        initial_books_cards = books_cards + [complete_partial_book]

        books = [Book(book_cards) for book_cards in initial_books_cards]
        points_in_books = sum([book.cards_value for book in books])

        if points_in_books < self.round.points_needed:
            raise IllegalActionError("Not enough points to lay down")

        player.add_card_to_hand_from_discard_pile(card)
        for book_cards in initial_books_cards:
            player.start_book(book_cards, self.round)

        player.laid_down()

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_start_book_action(self, player, cards):
        player.start_book(cards, self.round)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_add_cards_from_hand_to_book_action(self, player, cards, book_rank):
        player.add_cards_from_hand_to_book(cards, book_rank, self.round)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def end_round_with_player_going_out(self, player):
        if player is not None:
            player.add_bonus_for_going_out(self.round)

        for player in self.players:
            player.calculate_points(self.round)
            player.round_ended()

        self.discard_pile = []
        self.round = self.round.next_round

        if self.round is not None:
            for player in self.players:
                self.deal_cards_to_player(player)
                player.calculate_points(self.round)

    def to_json(self):
        return {
            "discard_pile": [card.to_json() for card in self.discard_pile],
            "players": [player.to_json() for player in self.players]
        }

#
# Engine
#

class Engine(object):

    def __init__(self, player_names):
        self.player_names = player_names

    @property
    def current_player(self):
        return self.game.player_iterator.current_player

    def generate_initial_game_state(self):
        standard_deck_count = len(self.player_names) + 1

        decks = {
            Round.NINETY.value: Deck(standard_deck_count),
            Round.ONE_TWENTY.value: Deck(standard_deck_count),
            Round.ONE_FIFTY.value: Deck(standard_deck_count),
            Round.ONE_EIGHTY.value: Deck(standard_deck_count)
        }

        for (current_round, deck) in decks.items():
            deck.shuffle()
            decks[current_round] = deck.to_json()

        return {
            "decks": decks
        }

    def start_game_with_initial_state(self, initial_state):
        decks = {
            Round.NINETY: Deck.from_json(initial_state["decks"][Round.NINETY.value]),
            Round.ONE_TWENTY: Deck.from_json(initial_state["decks"][Round.ONE_TWENTY.value]),
            Round.ONE_FIFTY: Deck.from_json(initial_state["decks"][Round.ONE_FIFTY.value]),
            Round.ONE_EIGHTY: Deck.from_json(initial_state["decks"][Round.ONE_EIGHTY.value])
        }

        self.game = Game(self.player_names, decks)

    def apply_action(self, action_json):
        action = Action.from_json(action_json)
        self.game.apply_action(action)

#
# Testing Support
#

def main(test_case):
    player_names = test_case["players"]
    actions_json = test_case["actions"]

    decks = {
        Round.NINETY: Deck.from_json(test_case["ninety_deck"]),
        Round.ONE_TWENTY: Deck.from_json(test_case["one_twenty_deck"]),
        Round.ONE_FIFTY: Deck.from_json(test_case["one_fifty_deck"]),
        Round.ONE_EIGHTY: Deck.from_json(test_case["one_eighty_deck"]),
    }

    game = Game(player_names, decks)
    actions = [Action.from_json(action_json) for action_json in actions_json]

    for i, action in enumerate(actions):
        try:
            game.apply_action(action)
        except IllegalActionError as e:
            sys.stderr.write("IllegalActionError at action %d: %s\n" % (i, e))
            break
        except Exception as e:
            sys.stderr.write("Unknown error applying action %d: %s\n" % (i, e))
            break

    final_state_json = game.to_json()
    print(json.dumps(final_state_json, indent=4))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Gimme a test case to run!")
        sys.exit(1)

    test_case_file_path = sys.argv[1]

    try:
        test_case_file = open(test_case_file_path, "r")
        test_case = json.load(test_case_file)
    except IOError as e:
        print("Couldn't open the given test case file: " + str(e))
        sys.exit(1)
    except ValueError as e:
        print("Couldn't read the given test case file as JSON: " + str(e))
        sys.exit(1)

    main(test_case)
