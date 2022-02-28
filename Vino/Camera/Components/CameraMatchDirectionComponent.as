class UCameraMatchDirectionComponent : UHazeCameraParentComponent
{
    // If true, camera will be forced to match direction of component while blending in.
    UPROPERTY()
    bool bMatchDirection = true;

    UPROPERTY()
    EHazeCameraPriority Priority = EHazeCameraPriority::High;

   	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
        if (bMatchDirection)
        {
            AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
            if (PlayerUser != nullptr)
            {
                FHazePointOfInterest POI;
                POI.FocusTarget.Actor = GetOwner();
                POI.FocusTarget.Component = this;
                POI.bMatchFocusDirection = true;
                POI.Blend.BlendTime = PlayerUser.GetRemainingBlendTime(Camera);
                POI.Duration = POI.Blend.BlendTime;
                PlayerUser.ApplyPointOfInterest(POI, this, Priority);     
            }
        }
	}

   	UFUNCTION(BlueprintOverride)
    void Snap()
    {
        if ((Camera == nullptr) || (Camera.GetUser() == nullptr))
            return;

        if (bMatchDirection)
        {
            AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(Camera.GetUser().GetOwner());
            if (PlayerUser != nullptr)
            {
                FHazePointOfInterest POI;
                POI.FocusTarget.Actor = GetOwner();
                POI.FocusTarget.Component = this;
                POI.bMatchFocusDirection = true;
                POI.Blend.BlendTime = 0.f;
                POI.Duration = POI.Blend.BlendTime;
                PlayerUser.ApplyPointOfInterest(POI, this, Priority);     
            }
        }
    }

   	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
        AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
        if (PlayerUser != nullptr)
        {
            PlayerUser.ClearPointOfInterestByInstigator(this);            
        }
    }
}