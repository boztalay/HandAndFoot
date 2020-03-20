import enum
import itertools
import random

@enum.unique
class CardSuit(enum.Enum):
    HEARTS = enum.auto()
    DIAMONDS = enum.auto()
    CLUBS = enum.auto()
    SPADES = enum.auto()

@enum.unique
class CardRank(enum.Enum):
    TWO = enum.auto()
    THREE = enum.auto()
    FOUR = enum.auto()
    FIVE = enum.auto()
    SIX = enum.auto()
    SEVEN = enum.auto()
    EIGHT = enum.auto()
    NINE = enum.auto()
    TEN = enum.auto()
    JACK = enum.auto()
    QUEEN = enum.auto()
    KING = enum.auto()
    ACE = enum.auto()

class Card(object):
    def __init__(self, suit, rank):
        self.suit = suit
        self.rank = rank

class Deck(object):
    def __init__(self, standardDeckCount):
        self.cards = []

        for _ in range(0, standardDeckCount):
            self.cards.extend(self.generateStandardDeck())

    def generateStandardDeck(self):
        return itertools.product(list(CardSuit), list(CardRank))

    def shuffle(self):
        random.shuffle(self.cards)

    def drawCard(self):
        if len(self.cards) > 0:
            return self.cards.pop()
        else:
            return None
