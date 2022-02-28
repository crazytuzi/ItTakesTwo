class ULocomotionFeatureGrindButton : UHazeLocomotionFeatureBase
{

    default Tag = n"GrindButton";

	// Button interaction
	UPROPERTY(Category = "Button Interaction")
	FHazePlaySequenceData ReadyToPressBtn;

	UPROPERTY(Category = "Button Interaction")
	FHazePlaySequenceData PressButton;

	// PressButton animation will trigger when the player is X units away from the button
	UPROPERTY(Category = "Button Interaction")
	float TriggerDistance = 400.f;

}