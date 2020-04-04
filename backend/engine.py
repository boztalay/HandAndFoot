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

class Deck(object):

    @staticmethod
    def from_json(deck_json):
        deck = Deck()

        for card_json in deck_json:
            deck.cards.append(Card.from_json(card_json))

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

class Player(object):

    def __init__(self, name, hand, foot):
        if len(hand) != 13 or len(foot) != 13:
            raise IllegalSetupError("Initial hand or foot not sized correctly")

        self.name = name
        self.hand = hand
        self.foot = foot
        self.books = {}
        self.points = {
            Round.NINETY: Points(),
            Round.ONE_TWENTY: Points(),
            Round.ONE_FIFTY: Points(),
            Round.ONE_EIGHTY: Points()
        }

        self.cards_drawn_from_deck = 0
        self.cards_drawn_from_discard_pile = 0
        self.has_laid_down_this_round = False

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

    @property
    def can_go_out(self):
        return (self.has_natural_book and self.has_unnatural_book and self.is_in_foot)

    @property
    def has_natural_book(self):
        return (len([book for book in self.books if book.is_natural]) > 0)

    @property
    def has_unnatural_book(self):
        return (len([book for book in self.books if not book.is_natural]) > 0)

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

    def add_card_to_book_from_hand(self, card):
        if card.rank not in self.books:
            raise IllegalActionError("Player doesn't have a book for the given card")

        self.remove_card_from_hand(card)
        self.books[card.rank].add_card(card)

    def add_card_to_book_from_discard_pile(self, card):
        if card.rank not in self.books:
            raise IllegalActionError("Player doesn't have a book for the given card")

        self.books[card.rank].add_card(card)
        self.cards_drawn_from_discard_pile += 1

    def start_book(self, cards):
        book = Book(cards)

        if book.rank in self.books:
            raise IllegalActionError("Player already has a book of the given rank")

        for card in cards:
            self.remove_card_from_hand(card)

        self.books[book.rank] = book

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
        self.points[current_round].in_books = sum([book.book_value for book in self.books])
        self.points[current_round].laid_down = sum([book.cards_value for book in self.books])

    def add_bonus_for_going_out(self, current_round):
        self.points[current_round].for_going_out = 100

#
# Actions
#

class Action(abc.ABC):

    @staticmethod
    def from_json(action_json):
        action_type = action_json["type"]

        if action_type == "draw_from_deck":
            return DrawFromDeckAction(action_json["player"])
        elif action_type == "draw_from_discard_and_add_to_book":
            return DrawFromDiscardAndAddToBookAction(action_json["player"])
        elif action_type == "draw_from_discard_and_create_book":
            cards = [Card.from_json(card_json) for card_json in action_json["cards"]]
            return DrawFromDiscardAndCreateBookAction(action_json["player"], cards)
        elif action_type == "dicard_card":
            card = Card.from_json(action_json["card"])
            return DiscardCardAction(action_json["player"], card)
        elif action_type == "lay_down_initial_books":
            books = [[Card.from_json(card_json) for card_json in cards_json] for cards_json in action_json["books"]]
            return LayDownInitialBooksAction(action_json["player"], books)
        elif action_type == "draw_from_discard_and_lay_down_initial_books":
            partial_book = [Card.from_json(card_json) for card_json in action_json["partial_book"]]
            books = [[Card.from_json(card_json) for card_json in cards_json] for cards_json in action_json["books"]]
            return DrawFromDiscardAndLayDownInitialBooksAction(action_json["player"], partial_book, books)
        elif action_type == "start_book":
            cards = [Card.from_json(card_json) for card_json in action_json["cards"]]
            return StartBookAction(action_json["player"], cards)
        elif action_type == "add_card_from_hand_to_book":
            card = Card.from_json(action_json["card"])
            return AddCardFromHandToBookAction(action_json["player"], card)

    def __init__(self, player_name):
        self.player_name = player_name

class DrawFromDeckAction(Action):
    def __init__(self, player_name):
        super().__init__(player_name)

class DrawFromDiscardAndAddToBookAction(Action):
    def __init__(self, player_name):
        super().__init__(player_name)

class DrawFromDiscardAndCreateBookAction(Action):
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

class DrawFromDiscardAndLayDownInitialBooksAction(Action):
    def __init__(self, player_name, partial_book, books):
        super().__init__(player_name)
        self.partial_book = partial_book
        self.books = books

class StartBookAction(Action):
    def __init__(self, player_name, cards):
        super().__init__(player_name)
        self.cards = cards

class AddCardFromHandToBookAction(Action):
    def __init__(self, player_name, card):
        super().__init__(player_name)
        self.card = card

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

    def __init__(self, player_names, deck=None):
        if len(player_names) < 2:
            raise IllegalSetupError("Not enough players")

        if len(player_names) > 6:
            raise IllegalSetupError("Too many players")

        if deck is not None:
            self.deck = deck
        else:
            deck_count = len(player_names) + 1
            self.deck = Deck(deck_count)
            self.deck.shuffle()

        self.discard_pile = []
        self.round = Round.NINETY

        self.players = [] 
        for player_name in player_names:
            player = self.set_up_player(player_name)
            self.players.append(player)

        self.player_iterator = PlayerIterator(self.players)

    def set_up_player(self, player_name):
        hand = []
        for _ in range(0, 13):
            hand.append(self.deck.draw())

        foot = []
        for _ in range(0, 13):
            foot.append(self.deck.draw())

        return Player(player_name, hand, foot)

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
        elif type(action) is DrawFromDiscardAndAddToBookAction:
            self.apply_draw_from_discard_and_add_to_book_action(player)
        elif type(action) is DrawFromDiscardAndCreateBookAction:
            self.apply_draw_from_discard_and_create_book_action(player, action.cards)
        elif type(action) is DiscardCardAction:
            self.apply_discard_card_action(player, action.card)
        elif type(action) is LayDownInitialBooksAction:
            self.apply_lay_down_initial_books_action(player, action.cards)
        elif type(action) is DrawFromDiscardAndLayDownInitialBooksAction:
            self.apply_draw_from_discard_and_lay_down_initial_books_action(player, action.partial_book, action.cards)
        elif type(action) is StartBookAction:
            self.apply_start_book_action(player, action.cards)
        elif type(action) is AddCardFromHandToBookAction:
            self.apply_add_card_from_hand_to_book_action(player, action.card)
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

    def apply_draw_from_discard_and_add_to_book_action(self, player):
        if not player.can_draw_from_discard_pile or not player.has_laid_down_this_round:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.discard_pile.pop()
        player.add_card_to_book_from_discard_pile(card)

    def apply_draw_from_discard_and_create_book_action(self, player, cards):
        if not player.can_draw_from_discard_pile:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.discard_pile.pop()
        cards.append(card)

        player.add_card_to_hand_from_discard_pile(card)
        player.start_book(cards)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_discard_card_action(self, player, card):
        if not player.can_end_turn:
            raise IllegalActionError("Cannot end turn yet")

        player.remove_card_from_hand(card)
        self.discard_pile.append(card)

        if player.is_hand_empty and player.is_in_foot:
            if not player.can_go_out:
                raise IllegalActionError("Cannot go out")

            self.end_round_with_player_going_out(player)
        else:
            if player.is_hand_empty:
                player.pick_up_foot()

            player.turn_ended()
            self.player_iterator.go_to_next_player()

    def apply_lay_down_initial_books_action(self, player, cards):
        if player.has_laid_down_this_round:
            raise IllegalActionError("Already laid down this round")

        books = [Book(cards_in_book) for cards_in_book in cards]
        points_in_books = sum([book.cards_value for book in books])

        if points_in_books < self.round.points_needed:
            raise IllegalActionError("Not enough points to lay down")

        for cards_in_book in cards:
            player.start_book(cards_in_book)

        player.laid_down()

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_draw_from_discard_and_lay_down_initial_books_action(self, player, partial_book, cards):
        if player.has_laid_down_this_round:
            raise IllegalActionError("Already laid down this round")

        if not player.can_draw_from_discard_pile:
            raise IllegalActionError("Cannot draw from the discard pile")

        if len(self.discard_pile) == 0:
            raise IllegalActionError("Discard pile is empty")

        card = self.deck.draw()
        complete_partial_book = partial_book + [card]
        initial_books_cards = cards + [complete_partial_book]

        books = [Book(cards_in_book) for cards_in_book in cards]
        points_in_books = sum([book.cards_value for book in books])

        if points_in_books < self.round.points_needed:
            raise IllegalActionError("Not enough points to lay down")

        for cards_in_book in cards:
            player.start_book(cards_in_book)

        player.laid_down()

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_start_book_action(self, player, cards):
        player.start_book(cards)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def apply_add_card_from_hand_to_book_action(self, player, card):
        player.add_card_to_book_from_hand(card)

        if player.is_hand_empty and not player.is_in_foot:
            player.pick_up_foot()

    def end_round_with_player_going_out(self, player):
        for player in self.players:
            player.round_ended()

        if player is not None:
            player.add_bonus_for_going_out(self.round)

        self.round = self.round.next_round

#
# Testing Support
#

def main(test_case):
    player_names = test_case["players"]
    initial_deck_json = test_case["initial_deck"]
    actions_json = test_case["actions"]

    deck = Deck.from_json(initial_deck_json)
    game = Game(player_names, deck)

    actions = [Action.from_json(action_json) for action_json in actions_json]

    for action in actions:
        try:
            game.apply_action(action)
        except IllegalActionError as e:
            sys.stderr.write("IllegalActionError: %s\n" % (e))
            break
        except Exception as e:
            sys.stderr.write("Unknown error applying an action: %s\n" % (e))
            break

    final_state_json = game.to_json()
    print(json.dumps(final_state_json), indent=4)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Gimme a test case to run!")
        sys.exit(1)

    test_case_file_path = sys.argv[1]

    try:
        test_case_file = open(test_case_file_path, "r")
        test_case = json.load(test_case_file)
    except IOError as e:
        print("Couldn't open the given test case file: " + str(e))
    except ValueError as e:
        print("Couldn't read the given test case file as JSON: " + str(e))

    main(test_case)
