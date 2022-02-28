import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachine;

/*
Used by capabilities to get a reference to the current drum machine
*/

void SetDrumMachineReference(AHazePlayerCharacter Player, AHazeActor DrumMachineRef)
{
	if(Player == nullptr)
		return;

	ADrumMachine DrumMachine = Cast<ADrumMachine>(DrumMachineRef);

	UPlayerDrumMachineComponent DrumComp = UPlayerDrumMachineComponent::GetOrCreate(Player);
	DrumComp.DrumMachine = DrumMachine;
}

class UPlayerDrumMachineComponent : UActorComponent
{
	ADrumMachine DrumMachine;

	UPROPERTY(Category = Animation)
	UAnimSequence PressButtonAnimation;

	// Duration that movement is prevented from the start of the animation.
	UPROPERTY(Category = Animation)
	float PreventMovementTime = 0.25f;

	UPROPERTY(Category = Animation)
	float BlendTime = 0.0f;
}
