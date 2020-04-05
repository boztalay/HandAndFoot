import json
import re
import sys

CARD_REGEX = re.compile(r"(\d|\d\d|[jqkar])([hdcs])")

RANKS = {
    "2": "two",
    "3": "three",
    "4": "four",
    "5": "five",
    "6": "six",
    "7": "seven",
    "8": "eight",
    "9": "nine",
    "10": "ten",
    "j": "jack",
    "q": "queen",
    "k": "king",
    "a": "ace",
    "r": "joker"
}

SUITS = {
    "h": "hearts",
    "d": "diamonds",
    "c": "clubs",
    "s": "spades"
}

def main():
    players = []
    while True:
        player_name = input("Player: ")
        if len(player_name) == 0:
            break

        players.append(player_name)

    if len(players) < 2 or len(players) > 6:
        print("Player count out of range")
        sys.exit(1)

    current_player_index = 0
    player = players[current_player_index]

    actions = []

    print()
    print_menu()

    try:
        while True:
            command = input(f"[{player}]$ ")

            if command == "1":
                action = build_draw_from_deck_action()
            elif command == "2":
                action = build_draw_from_discard_pile_and_add_to_book_action()
            elif command == "3":
                action = build_draw_from_discard_pile_and_create_book_action()
            elif command == "4":
                action = build_discard_card_action()
            elif command == "5":
                action = build_lay_down_initial_books_action()
            elif command == "6":
                action = build_draw_from_discard_pile_and_lay_down_initial_books_action()
            elif command == "7":
                action = build_start_book_action()
            elif command == "8":
                action = build_add_card_from_hand_to_book_action()
            elif command == "u":
                actions = actions[:-1]
                print("Action removed, latest action is now:")
                print(actions[-1])
                continue
            elif command == "n":
                current_player_index = (current_player_index + 1) % len(players)
                player = players[current_player_index]
                print(f"Player is now {player}")
                continue
            elif command == "p":
                current_player_index = (current_player_index - 1) % len(players)
                player = players[current_player_index]
                print(f"Player is now {player}")
                continue
            elif command == "h":
                print_menu()
                continue
            else:
                continue

            actions.append(action)
            print(action)
            print()
    except KeyboardInterrupt:
        pass

    print()
    print(json.dumps(actions, indent=4))

def build_draw_from_deck_action():
    return {
        "type": "draw_from_deck"
    }

def build_draw_from_discard_pile_and_add_to_book_action():
    return {
        "type": "draw_from_discard_pile_and_add_to_book"
    }

def build_draw_from_discard_pile_and_create_book_action():
    return {
        "type": "draw_from_discard_pile_and_create_book",
        "cards": ask_for_cards()
    }

def build_discard_card_action():
    return {
        "type": "discard_card",
        "card": ask_for_card()
    }

def build_lay_down_initial_books_action():
    books = []

    for i in range(0, 10):
        print("Book %d:" % (i + 1))
        cards = ask_for_cards()

        if len(cards) == 0:
            break
        else:
            books.append(cards)

    return {
        "type": "lay_down_initial_books",
        "books": books
    }

def build_draw_from_discard_pile_and_lay_down_initial_books_action():
    print("Partial book:")
    parital_book = ask_for_cards()

    books = []
    for i in range(0, 10):
        print("Book %d:" % (i + 1))
        cards = ask_for_cards()

        if len(cards) == 0:
            break
        else:
            books.append(cards)

    return {
        "type": "draw_from_discard_pile_and_lay_down_initial_books",
        "parital_book": parital_book,
        "books": books
    }

def build_start_book_action():
    return {
        "type": "start_book",
        "cards": ask_for_cards()
    }

def build_add_card_from_hand_to_book_action():
    return {
        "type": "add_card_from_hand_to_book",
        "card": ask_for_card()
    }

def ask_for_card():
    while True:
        card_string = input("Card: ")
        if len(card_string) == 0:
            return None

        match = CARD_REGEX.match(card_string)
        if match is None:
            print("    Invalid card")
            continue

        try:
            rank = RANKS[match.group(1)]
            suit = SUITS[match.group(2)]
        except KeyError:
            print("    Invalid card")
            continue

        return {
            "suit": suit,
            "rank": rank
        }

def ask_for_cards():
    cards = []

    while True:
        card = ask_for_card()
        if card is None:
            break
        else:
            cards.append(card)

    return cards

def print_menu():
    print(f"Menu:")
    print("    1. Draw from deck")
    print("    2. Draw from discard pile and ADD TO book")
    print("    3. Draw from discard pile and CREATE book")
    print("    4. Discard card")
    print("    5. Lay down initial books")
    print("    6. Draw from discard pile and lay down initial books")
    print("    7. Start book")
    print("    8. Add card from hand to book")
    print("    u. Undo last action")
    print("    n. Got to next player")
    print("    p. Got to previous player")
    print("    h. Print this menu")
    print()

if __name__ == "__main__":
    main()
