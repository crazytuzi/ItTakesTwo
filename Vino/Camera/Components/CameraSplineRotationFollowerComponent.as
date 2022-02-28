import Vino.Camera.Components.CameraSplineFollowerComponent;

UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UCameraSplineRotationFollowerComponent : UHazeCameraParentComponent
{
	// The spline this component will get it's rotation from
	UPROPERTY()
	UHazeSplineComponentBase CameraSpline = nullptr;

	// Rotation offset from spline tangent (e.g. Yaw -90 if left orthogonal of spline tangent)
	UPROPERTY()
	FRotator RotationOffset = FRotator(-45.f, -90.f, 0.f);

	// How fast we move along the spline  
	UPROPERTY()
	float FollowSpeed = 1.f;

	// The camera is offset this many units behind the follow target along the camera spline.
	UPROPERTY()
	float BackwardsOffset = 0.f;

	// How do we choose which location we should follow?
	UPROPERTY(AdvancedDisplay)
	ESplineFollowType FollowType = ESplineFollowType::Weighted;

	// If true, we will follow dead players the same as alive ones. If false, we will only follow dead players if both players are dead.
	UPROPERTY()
	bool bAlwaysFollowDeadPlayers = false;
	bool bFollowBothPlayers = false;

	// If true we will apply this component as center component for clamps at same priority camera was activated with
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	bool bUseAsClampsCenter = false;

	// Follow target for the player activating this camera
	UPROPERTY(AdvancedDisplay)
	FSplineFollowTarget UserFollowTarget;
	default UserFollowTarget.Weight = 1.f;

	// Follow target for the player not activating this camera
	UPROPERTY(AdvancedDisplay)
	FSplineFollowTarget OtherPlayerFollowTarget;

	// Additional follow targets
	UPROPERTY(AdvancedDisplay)
	TArray<FSplineFollowTarget> FollowTargets;

	FHazeAcceleratedFloat DistanceAlongSpline;
	AHazePlayerCharacter PlayerUser = nullptr;
	TArray<FSplineFollowTarget> AllFollowTargets; // Includes player follow targets

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		// Add user and other player follow targets if appropriate.
		PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
		UserFollowTarget.Target.Actor = User.GetOwner();
		OtherPlayerFollowTarget.Target.Actor = (PlayerUser != nullptr) ? PlayerUser.GetOtherPlayer() : nullptr;
		InitializeFollowTargets(FollowTargets, UserFollowTarget, OtherPlayerFollowTarget, AllFollowTargets, bFollowBothPlayers);

		if (bUseAsClampsCenter && (PlayerUser != nullptr))
		{
			FHazeCameraClampSettings Clamps;
			Clamps.bUseCenterOffset = true;
			Clamps.CenterOffset = FRotator::ZeroRotator;
			Clamps.CenterType = EHazeCameraClampsCenterRotation::Component;
			Clamps.CenterComponent = this;
			PlayerUser.ApplyCameraClampSettings(Clamps, CameraBlend::MatchPrevious(), this, PlayerUser.GetActivationPriority(Camera));
		}

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Camera was not previously blending out or active
			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		if (PlayerUser != nullptr)
			PlayerUser.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		AllFollowTargets = FollowTargets;
	}

    UFUNCTION(BlueprintOverride)
    void Snap()
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (CameraSpline == nullptr))
			return;

		DistanceAlongSpline.Value = GetTargetDistanceAlongSpline(Camera.GetUser());
		DistanceAlongSpline.Velocity = 0.f;
		UpdateInternal(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (CameraSpline == nullptr))
			return;

		UpdateInternal(DeltaSeconds);
	}
 
	void UpdateInternal(float DeltaSeconds)
	{
		float SplineLength = CameraSpline.GetSplineLength();		
		float TargetDistAlongSpline = GetTargetDistanceAlongSpline(Camera.GetUser());
		if (CameraSpline.IsClosedLoop() && (FMath::Abs(TargetDistAlongSpline - DistanceAlongSpline.Value) > SplineLength * 0.5f))
		{
			// Looping past start/end if shorter than the other way around
			if (DistanceAlongSpline.Value > SplineLength * 0.5f)
				TargetDistAlongSpline += SplineLength;
			else
				TargetDistAlongSpline -= SplineLength;
		}
		if (FollowSpeed > 0.f)
		 	DistanceAlongSpline.AccelerateTo(TargetDistAlongSpline, 1.f / FollowSpeed, DeltaSeconds);  

		// In case of looping spline, we might need to mod the result
		if (DistanceAlongSpline.Value < 0.f)
			DistanceAlongSpline.Value += SplineLength;
		if (DistanceAlongSpline.Value > SplineLength)
			DistanceAlongSpline.Value -= SplineLength;
		
		FRotator NewRot = CameraSpline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline.Value, ESplineCoordinateSpace::World);
		SetWorldRotation(NewRot + RotationOffset);


	}

	// TODO: A bunch if common functionality with regular spline follower below, break out to static or spline function
	float GetTargetDistanceAlongSpline(UHazeCameraUserComponent User)
	{
		if (CameraSpline == nullptr)
			return 0.f;

		if (User.GetOwner() == nullptr)
			return 0.f;

		float Fraction = GetFollowFraction();
		float TargetDistance = Fraction * CameraSpline.GetSplineLength();
		TargetDistance -= BackwardsOffset;
		if (!CameraSpline.IsClosedLoop())
			TargetDistance = FMath::Clamp(TargetDistance, 0.f, CameraSpline.GetSplineLength());
		return TargetDistance;
	}

	float GetFollowFraction()
	{
		// If both players are dead, we allow them as focus targets
		bool bFollowDeadPlayers = bAlwaysFollowDeadPlayers || !bFollowBothPlayers || AreBothPlayersDead();
		switch (FollowType)
		{
			case ESplineFollowType::Foremost:
				return GetForemostFollowFraction(bFollowDeadPlayers);
			case ESplineFollowType::Rearmost:
				return GetRearmostFollowFraction(bFollowDeadPlayers);
		} 
		// case ESplineFollowType::Weighted:
		return GetWeightedFollowFraction(bFollowDeadPlayers);
	}

	float GetWeightedFollowFraction(bool bFollowDeadPlayers)
	{
		FVector LocationSum = FVector::ZeroVector;
		float WeightSum = 0.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			LocationSum += FolloweeLoc * FollowTarget.Weight;
			WeightSum += FollowTarget.Weight;

			// if (bDebugDraw) 
			// 	System::DrawDebugLine(FolloweeLoc, FolloweeLoc + FVector(0,0, FollowTarget.Weight * 100), FLinearColor::Yellow, 0, 3);
		}

		if (WeightSum == 0.f)
			return 0.f;

		// if (bDebugDraw) 
		// 	System::DrawDebugLine(LocationSum / WeightSum, LocationSum / WeightSum + FVector(0,0, WeightSum * 100), FLinearColor::Green, 0, 5);

		return CameraSpline.FindFractionClosestToWorldLocation(LocationSum / WeightSum);
	}

	float GetForemostFollowFraction(bool bFollowDeadPlayers)
	{
		float ForemostFraction = 0.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			float Fraction = CameraSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
			if (Fraction > ForemostFraction)
				ForemostFraction = Fraction;
		}

		// if (bDebugDraw)
		// 	DebugDrawPositionalFollowTargets(ForemostFraction);

		return ForemostFraction;
	}

	float GetRearmostFollowFraction(bool bFollowDeadPlayers)
	{
		float RearmostFraction = 1.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			float Fraction = CameraSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
			if (Fraction < RearmostFraction)
				RearmostFraction = Fraction;
		}

		// if (bDebugDraw)
		// 	DebugDrawPositionalFollowTargets(RearmostFraction);
	
		return RearmostFraction;
	}
}