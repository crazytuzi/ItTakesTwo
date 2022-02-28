import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonAimCapability;

UFUNCTION()
void ActivateCannon(AHazePlayerCharacter Player, ACastleCannon Cannon, UHazeCapabilitySheet ShooterSheet, UObject _Instigator)
{
	auto ShooterComp = UCastleCannonShooterComponent::GetOrCreate(Player);
	ShooterComp.ActiveCannon = Cannon;

	Player.AddCapabilitySheet(ShooterSheet, Instigator = _Instigator);
}