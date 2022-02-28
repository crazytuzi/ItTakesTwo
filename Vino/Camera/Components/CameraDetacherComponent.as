// Detaches from parent when activated, but moves along with parent in tick and reattaches when blended out
// Use when you want to get avoid issues with asynchronous movement outside of tick
class UCameraDetacherComponent : UHazeCameraParentComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	USceneComponent DetachedParent = nullptr;
	FTransform DefaultRelativeTransform;
	USceneComponent DefaultParent = nullptr;

	// If true we match detached parent rotation in tick.
	UPROPERTY()
	bool bFollowRotation = true;

	// If true we match detached parent location in tick.
	UPROPERTY()
	bool bFollowLocation = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultParent = GetAttachParent();
		DefaultRelativeTransform = RelativeTransform;	
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		DetachedParent = GetAttachParent();
		if (DetachedParent == nullptr)
			DetachedParent = DefaultParent;
		DetachFromParent(bMaintainWorldPosition = true);
	}

	UFUNCTION(BlueprintOverride)
    void OnCameraFinishedBlendingOut(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
    {
		if (DetachedParent == nullptr)
			DetachedParent = DefaultParent;

        if (DetachedParent != nullptr)
		{
            AttachToComponent(DetachedParent);
			SetRelativeTransform(DefaultRelativeTransform);
			DetachedParent = nullptr;
		}
    }

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		Update(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if (DetachedParent == nullptr)
			return;
		
		FTransform ParentTransform = DetachedParent.GetWorldTransform();
		FTransform NewTransform = DefaultRelativeTransform * ParentTransform;
		if (!bFollowLocation)
			NewTransform.SetLocation(GetWorldLocation());
		if (!bFollowRotation)
			NewTransform.SetRotation(GetWorldRotation());
		SetWorldTransform(NewTransform); 
	}
}

