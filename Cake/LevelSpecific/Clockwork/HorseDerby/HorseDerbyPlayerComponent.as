import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseComponent;

class UHorseDerbyPlayerComponent : UActorComponent
{
	EDerbyHorseMovementState MovementState = EDerbyHorseMovementState::Still;
	float CurrentProgress = 0.f;

	UDerbyHorseComponent HorseComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HorseComp != nullptr)
		{
			CurrentProgress = HorseComp.CurrentProgress;
			MovementState = HorseComp.MovementState;
		}
	}
}