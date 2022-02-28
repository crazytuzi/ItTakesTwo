event void FDrumMachineResetButtonPressed();

class UDrumMachineResetButtonComponent : UStaticMeshComponent
{
    default StaticMesh = Asset("/Engine/BasicShapes/Cube.Cube");
    default RelativeScale3D = FVector(1.f, 1.f, 1.f);

	FVector2D LocalMin;
	FVector2D LocalMax;

	UPROPERTY()
	FVector ButtonDetectionPadding = FVector(50.f, 50.f, 0.f);

	UPROPERTY()
	FDrumMachineResetButtonPressed OnPressed;

	FVector GetDetectionSize()
	{
		return RelativeScale3D * 200.f + ButtonDetectionPadding;
	} 

	void OnGroundPounded(AHazePlayerCharacter GroundPounder)
	{
		// Groundpounder controlling side decides if button should be turned on or off, don't toggle!
		if (!GroundPounder.HasControl())
			return;

		NetPressButton();
	}

	UFUNCTION(NetFunction)
	void NetPressButton()
	{
		OnPressed.Broadcast();
	}
}
