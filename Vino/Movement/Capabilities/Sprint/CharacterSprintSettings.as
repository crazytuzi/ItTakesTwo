import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
UCLASS(Meta = (ComposeSettingsOnto = "USprintSettings"))
class USprintSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MoveSpeed = 1300.f;

	UPROPERTY()
	float Acceleration = 3400.f;
	
	UPROPERTY()
	float TurnRate = 450.f;

	UPROPERTY()
	float Deceleration = 1400.f;

	UPROPERTY()
	float SlowdownDuration = 0.4f;
	
	UPROPERTY()
	float SpeedupDuration = 0.25f;	
}

UFUNCTION()
void ForceSprint(AHazePlayerCharacter Player, UObject Instigator)
{
	if (Player == nullptr)
		return;
	
	if (Instigator == nullptr)
		return;

	UCharacterSprintComponent SprintComp = UCharacterSprintComponent::GetOrCreate(Player);
	if (SprintComp == nullptr)
		return;	

	SprintComp.ForceSprint(Instigator);
}


UFUNCTION()
void ClearForceSprint(AHazePlayerCharacter Player, UObject Instigator)
{
	if (Player == nullptr)
		return;
	
	if (Instigator == nullptr)
		return;

	UCharacterSprintComponent SprintComp = UCharacterSprintComponent::GetOrCreate(Player);
	if (SprintComp == nullptr)
		return;	

	SprintComp.ClearForceSprint(Instigator);
}