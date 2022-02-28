
class UCameraFollowViewComponent : UHazeCameraParentComponent
{
	AHazePlayerCharacter PlayerUser;
	
	// If set, camera won't follow if view comes within DontFollowRange of this volume.
	UPROPERTY()
	AVolume DontFollowVolume = nullptr;

	// If there's a DontFollowVolume we won't follow view if it gets within this range from that volume.
	UPROPERTY()
	float DontFollowRange = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent CameraUser, EHazeCameraState PreviousState)
	{
		PlayerUser = Cast<AHazePlayerCharacter>(CameraUser.Owner);

		if(PreviousState == EHazeCameraState::Inactive)
		{
			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		Update(0);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaTime)
	{
		if ((DontFollowVolume != nullptr) && DontFollowVolume.EncompassesPoint(PlayerUser.ViewLocation, DontFollowRange))
			return;

		SetWorldLocationAndRotation(PlayerUser.ViewLocation, PlayerUser.ViewRotation);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			System::DrawDebugPoint(WorldLocation, 10.f, FLinearColor::Purple);		
#endif		
	}
}
