import re
import json

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
    cards = []

    try:
        while True:
            cardString = input("Card: ").strip()

            if cardString == "u":
                cards = cards[:-1]
                print("Latest card is now:")
                print(cards[-1])
                print()

            match = CARD_REGEX.match(cardString)
            if match is None:
                continue

            try:
                rank = RANKS[match.group(1)]
                suit = SUITS[match.group(2)]
            except KeyError:
                continue

            card = {
                "suit": suit,
                "rank": rank
            }

            cards.append(card)
            print(card)

            plural = "" if len(cards) == 1 else "s"
            print(f"{len(cards)} card{plural}\n")
    except KeyboardInterrupt:
        pass

    print()
    print(json.dumps(cards, indent=4))

if __name__ == "__main__":
    main()
