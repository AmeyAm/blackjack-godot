import random


class Card:
    rank: int
    suit: str

    def __init__(self, rank: int, suit: str) -> None:
        self.rank = rank
        self.suit = suit

    def __str__(self) -> str:
        names = {11: "J", 12: "Q", 13: "K", 14: "A"}
        return f"{names.get(self.rank, str(self.rank))} {self.suit}"


class Deck:
    def __init__(self) -> None:
        self.cards = [Card(r, s) for s in ["♠", "♥", "♦", "♣"] for r in range(2, 15)]

    def __str__(self) -> str:
        return " ".join(str(c) for c in self.cards)

    def __len__(self) -> int:
        return len(self.cards)

    def shuffle(self) -> None:
        random.shuffle(self.cards)

    def deal(self, count: int = 1) -> list[Card]:
        if count > len(self.cards):
            raise ValueError("Not enough cards")
        return [self.cards.pop() for _ in range(count)]


def hand_value(cards: list["Card"]) -> int:
    total = 0
    aces = 0
    for card in cards:
        if card.rank == 14:
            aces += 1
            total += 11
        else:
            total += min(card.rank, 10)
    while total > 21 and aces:
        total -= 10
        aces -= 1
    return total


if __name__ == "__main__":
    pbal = 100

    while pbal > 0:
        d = Deck()
        d.shuffle()

        print(f"Money: ${pbal}")
        bet = int(input("Bet: "))
        if bet > pbal:
            print("Cannot bet more than you already have")
            continue
        pbal -= bet

        dealer = []
        player = []

        player.extend(d.deal())
        dealer.extend(d.deal())
        player.extend(d.deal())
        dealer.extend(d.deal())

        while True:
            psum = hand_value(player)
            dsum = hand_value(dealer)

            if psum > 21:
                print("You lose")
                break

            print(f"Dealer: {dealer[0]}")

            print(f"Player: {[f'{c}' for c in player]} = {psum}")

            print("Choices: Hit, Stand [h/s]")

            choice = input("> ")

            match choice:
                case "h":
                    player.extend(d.deal())
                    psum = hand_value(player)
                    if psum > 21:
                        print(f"Dealer: {[f'{c}' for c in dealer]} = {dsum}")
                        print(f"Player: {[f'{c}' for c in player]} = {psum}")
                        print("You lose")
                        break
                case "s":
                    while dsum < 17:
                        dealer.extend(d.deal())
                        dsum = hand_value(dealer)

                    print(f"Dealer: {[f'{c}' for c in dealer]} = {dsum}")
                    print(f"Player: {[f'{c}' for c in player]} = {psum}")

                    if dsum > 21 or psum > dsum:
                        print("You win")
                        bet *= 2
                        pbal += bet
                        print(f"+ {bet}")
                    elif psum == dsum:
                        pbal += bet + (bet * 0.1)
                        print("Push - Earn 10% interest")
                        print(f"+ {bet * 0.1}")
                    else:
                        print("You lose")
                    break


# Hit — take another card
# Stand — take no more cards, end your turn
# Double down — double your bet, take exactly one more card, then stand
# Split — if you have two cards of the same rank, split into two separate hands (each gets a new card), playing each independently
# Surrender — forfeit half your bet and end the hand (not available everywhere)
# Insurance — side bet when dealer shows an Ace, pays 2:1 if dealer has blackjack (generally a bad bet)