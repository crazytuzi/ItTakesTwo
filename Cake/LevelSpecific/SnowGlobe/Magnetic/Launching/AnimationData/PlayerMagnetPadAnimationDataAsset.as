class UPlayerMagnetPadAnimationDataAsset : UDataAsset
{
	UPROPERTY()
	UHazeLocomotionStateMachineAsset NormalLocomotionStateMachine;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset PickupLocomotionStateMachine;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset SmallPickupLocomotionStateMachine;
}