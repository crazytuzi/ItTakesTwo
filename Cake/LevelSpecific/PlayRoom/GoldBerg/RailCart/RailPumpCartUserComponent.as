import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;
import Peanuts.Audio.AudioStatics;

class URailPumpCartUserComponent : UActorComponent
{
	ARailPumpCart PendingCart = nullptr;
	bool bPendingFront = false;

	UPROPERTY()
	ARailPumpCart CurrentCart = nullptr;

	UPROPERTY()
	bool bFront;

	UPROPERTY()
	bool bIsLocked = false;

	UPROPERTY()
	bool bTeleport = false;
}

void StartUsingRailPumpCart(AHazePlayerCharacter Player, ARailPumpCart Cart, bool bFront, bool bTeleport)
{
	auto Comp = URailPumpCartUserComponent::GetOrCreate(Player);
	Comp.PendingCart = Cart;
	Comp.bPendingFront = bFront;
	Comp.bTeleport = bTeleport;

	Player.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterIsAirborne, 0.f);
}

void StopUsingRailPumpCart(AHazePlayerCharacter Player)
{
	auto Comp = URailPumpCartUserComponent::GetOrCreate(Player);
	if (!ensure(Comp.CurrentCart != nullptr))
		return;

	if (Comp.bFront)
		Comp.CurrentCart.FrontPlayer = nullptr;
	else
		Comp.CurrentCart.BackPlayer = nullptr;
	Comp.CurrentCart = nullptr;
}