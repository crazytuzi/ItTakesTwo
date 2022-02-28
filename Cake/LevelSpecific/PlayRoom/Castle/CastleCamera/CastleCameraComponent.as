import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;

UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UCastleCameraComponent : UHazeCameraParentComponent
{

	// The spline this component will move along
	UPROPERTY()
	UHazeSplineComponentBase CameraSpline = nullptr;

	// The spline against which we will check the followers location to see how far along the CameraSpline we should be.
	// If guide spline is null, the follow spline will be used as guide spline. 
	UPROPERTY()
	UHazeSplineComponentBase GuideSpline = nullptr;

	// How fast we move along the spline  
	UPROPERTY()
	float FollowSpeed = 1.f;

	// The camera is offset this many units behind the follow target along the camera spline.
	UPROPERTY()
	float BackwardsOffset = 0.f;

	// How do we choose which location we should follow?
	UPROPERTY(AdvancedDisplay)
	ESplineFollowType FollowType = ESplineFollowType::Weighted;

	// Follow target for the player activating this camera
	UPROPERTY(AdvancedDisplay)
	FSplineFollowTarget UserFollowTarget;
	default UserFollowTarget.Weight = 1.f;

	// Follow target for the player not activating this camera
	UPROPERTY(AdvancedDisplay)
	FSplineFollowTarget OtherPlayerFollowTarget;
	default OtherPlayerFollowTarget.Weight = 1.f;

	// Additional follow targets
	UPROPERTY(AdvancedDisplay)
	TArray<FSplineFollowTarget> FollowTargets;

	// If not None any clamps of the camera will be modified according to this property
	UPROPERTY(AdvancedDisplay)
	ESplineFollowClampType ClampsModifier = ESplineFollowClampType::None;

	FHazeAcceleratedFloat DistanceAlongSpline;
	AHazePlayerCharacter PlayerUser = nullptr;
	TArray<FSplineFollowTarget> AllFollowTargets; // Includes player follow targets

	// The keep in view component we should handle focus targets for, if any
	UCameraKeepInViewComponent KeepInViewComp = nullptr;
	
	// We will take these extra targets into account for the keep in view comp
	TArray<FExtraFocusTarget> ExtraFocusTargets;
	FHazeAcceleratedVector ExtraFocusTargetOffset;

#if EDITOR
	float PreviewSplineFraction = 0.f;
#endif

	//bool bDebugDraw = false;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		// Ensure we have a guide spline
		if (GuideSpline == nullptr)
			GuideSpline = CameraSpline;
		
		// Check if we have a keep in view component to handle
		KeepInViewComp = nullptr;
		TArray<USceneComponent> Children;
		GetChildrenComponents(true, Children);
		for (USceneComponent Child : Children)
		{
			KeepInViewComp = Cast<UCameraKeepInViewComponent>(Child);
			if (KeepInViewComp != nullptr)
				break;
		}

		// Add user and other player follow targets if appropriate.
		AllFollowTargets = FollowTargets;
		PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
		if (PlayerUser != nullptr)
		{
			if (UserFollowTarget.Weight > 0.f)
			{
				UserFollowTarget.Target.Actor = PlayerUser;
				AllFollowTargets.Add(UserFollowTarget);
			}
			if (OtherPlayerFollowTarget.Weight > 0.f)
			{
				AHazePlayerCharacter OtherPlayer = PlayerUser.GetOtherPlayer();
				if (OtherPlayer != nullptr)
				{
					OtherPlayerFollowTarget.Target.Actor = OtherPlayer;
					AllFollowTargets.Add(OtherPlayerFollowTarget);
				}
			}
		}

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Camera was not previously blending out or active, snap
			Snap();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		AllFollowTargets = FollowTargets;
		PlayerUser.ClearCameraSettingsByInstigator(this);
	}

    UFUNCTION(BlueprintOverride)
    void Snap()
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (CameraSpline == nullptr))
			return;

		if (GuideSpline	== nullptr)
			GuideSpline = CameraSpline;

		DistanceAlongSpline.Value = GetTargetDistanceAlongSpline(Camera.GetUser());
		DistanceAlongSpline.Velocity = 0.f;
		Update(0.f);

		if (KeepInViewComp != nullptr)
			UpdateKeepInViewTarget(0.f, true);	
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (CameraSpline == nullptr))
			return;

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
		
		FVector NewDirection = CameraSpline.GetTangentAtDistanceAlongSpline(DistanceAlongSpline.Value, ESplineCoordinateSpace::World);
		FRotator NewRotation = NewDirection.Rotation();

		NewRotation.Yaw = FRotator::NormalizeAxis(NewRotation.Yaw - 90.f);		
		SetWorldRotation(NewRotation);

		UpdateKeepInViewTarget(DeltaSeconds, false);
	}

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
		bool bFollowDeadPlayers = (((Game::GetMay() == nullptr) || IsPlayerDead(Game::GetMay())) && 
								   ((Game::GetCody() == nullptr) || IsPlayerDead(Game::GetCody())));
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

		return GuideSpline.FindFractionClosestToWorldLocation(LocationSum / WeightSum);
	}

	float GetForemostFollowFraction(bool bFollowDeadPlayers)
	{
		float ForemostFraction = 0.f;
		for (FSplineFollowTarget FollowTarget : AllFollowTargets)
		{
			if (!FollowTarget.IsValid(bFollowDeadPlayers))
				continue;
			FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
			float Fraction = GuideSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
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
			float Fraction = GuideSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
			if (Fraction < RearmostFraction)
				RearmostFraction = Fraction;
		}

		// if (bDebugDraw)
		// 	DebugDrawPositionalFollowTargets(RearmostFraction);
	
		return RearmostFraction;
	}

	// void DebugDrawPositionalFollowTargets(float BestFraction)
	// {
	// 	for (FSplineFollowTarget FollowTarget : AllFollowTargets)
	// 	{
	// 		if (!FollowTarget.IsValid())
	// 			continue;
	// 		FVector FolloweeLoc = FollowTarget.Target.GetFocusLocation(PlayerUser);
	// 		float Fraction = GuideSpline.FindFractionClosestToWorldLocation(FolloweeLoc);
	// 		if (Fraction == BestFraction)
	// 			System::DrawDebugLine(FolloweeLoc, FolloweeLoc + FVector(0,0, 300), FLinearColor::Green, 0, 5);
	// 		else
	// 			System::DrawDebugLine(FolloweeLoc, FolloweeLoc + FVector(0,0, 100), FLinearColor::Yellow, 0, 3);
	// 	}
	// }

	void ModifyClamps(float DistAlongSpline, FHazeCameraClampSettings& InOutClamps)
	{
		if (ClampsModifier == ESplineFollowClampType::None)
			return;

		if (!InOutClamps.IsUsed())
			return;

		// Modify clamps to offset relative to tangent, in world space
		FRotator ClampCenter = CameraSpline.GetTangentAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World).Rotation();
		if (ClampsModifier == ESplineFollowClampType::TangentLeft)
			ClampCenter.Yaw = FRotator::NormalizeAxis(ClampCenter.Yaw - 90.f);
		else if (ClampsModifier == ESplineFollowClampType::TangentRight)
			ClampCenter.Yaw = FRotator::NormalizeAxis(ClampCenter.Yaw + 90.f);

		InOutClamps.CenterType = EHazeCameraClampsCenterRotation::WorldSpace;
		InOutClamps.bUseCenterOffset = true;
		InOutClamps.CenterOffset = ClampCenter;	

		// FRotator AvgCenter = InOutClamps.CenterOffset;
		// AvgCenter.Yaw += 0.5f * (InOutClamps.ClampYawLeft + InOutClamps.ClampYawRight) - InOutClamps.ClampYawLeft;
		// Debug::DrawDebugArc(InOutClamps.ClampYawLeft + InOutClamps.ClampYawRight, 
		// CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World), 1000.f, 
		// AvgCenter.Vector(), FLinearColor::Green, 5.f, FVector::UpVector);	
	}	

	void UpdateKeepInViewTarget(float DeltaTime, bool bSnap)
	{
		if (KeepInViewComp == nullptr)
			return;

		AHazePlayerCharacter ViewPlayer = SceneView::GetFullScreenPlayer();
		if (ViewPlayer == nullptr)
			ViewPlayer = PlayerUser;

		// Calculate base offset
		FHazeFocusTarget FocusTarget;
		FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		FVector MayLoc = Game::May.ActorLocation;
		FVector CodyLoc = Game::Cody.ActorLocation;
		FVector CenterLoc = (CodyLoc + MayLoc) * 0.5f;
		FocusTarget.WorldOffset = CenterLoc;

		// Extra target value in view spaxce, use abs(Z) for height
		ViewPlayer.ViewTransform.InverseTransformVector(ExtraFocusTargetOffset.Value);

		// Calculate offset for any targets other than players
		const float ExtraTargetsWeight = 0.5f;
		const float ExtraTargetsBlendTime = 1.f;
		FVector IdealOffsetFromExtraTargets = FVector::ZeroVector;
		ExtraFocusTargets = Cast<UCastleCameraComponent>(TemplateComponent).ExtraFocusTargets;
		if (ExtraFocusTargets.Num() > 0)
		{
			FVector ViewForward = ViewPlayer.ViewRotation.ForwardVector;
			FVector ViewRight = ViewPlayer.ViewRotation.RightVector;
			FVector ViewUp = ViewPlayer.ViewRotation.UpVector;
			for (FExtraFocusTarget ExtraTarget : ExtraFocusTargets)
			{
				FVector Offset = ExtraTarget.Target.ActorLocation - CenterLoc;

				FVector XOffset = ViewForward * Offset.DotProduct(ViewForward);
				FVector YOffset = ViewRight * Offset.DotProduct(ViewRight);
				FVector ZOffset = ViewUp * Offset.DotProduct(ViewUp);

				FVector ToMayLocal = ViewPlayer.ViewTransform.InverseTransformVector(Game::May.ActorLocation - ExtraTarget.Target.ActorLocation);
				FVector ToCodyLocal = ViewPlayer.ViewTransform.InverseTransformVector(Game::Cody.ActorLocation - ExtraTarget.Target.ActorLocation);
				FVector ToMayLocalAbs = ToMayLocal.Abs;
				FVector ToCodyLocalAbs = ToCodyLocal.Abs;

				if (FMath::Sign(ToMayLocal.X) != FMath::Sign(ToCodyLocal.X))
					XOffset = 0.f;
				else
				{
					XOffset *= FMath::GetMappedRangeValueClamped(
						FVector2D(100.f, XOffset.Size()),
						FVector2D(0.f, 1.f), FMath::Min(ToMayLocalAbs.X, ToCodyLocalAbs.X));
				}

				if (FMath::Sign(ToMayLocal.Y) != FMath::Sign(ToCodyLocal.Y))
					YOffset = 0.f;
				else
				{
					YOffset *= FMath::GetMappedRangeValueClamped(
						FVector2D(100.f, YOffset.Size()),
						FVector2D(0.f, 1.f), FMath::Min(ToMayLocalAbs.Y, ToCodyLocalAbs.Y));
				}

				if (FMath::Sign(ToMayLocal.Z) != FMath::Sign(ToCodyLocal.Z))
					ZOffset = 0.f;
				else
				{
					ZOffset *= FMath::GetMappedRangeValueClamped(
						FVector2D(100.f, ZOffset.Size()),
						FVector2D(0.f, 1.f), FMath::Min(ToMayLocalAbs.Z, ToCodyLocalAbs.Z));
				}

				Offset = XOffset + YOffset + ZOffset;
				IdealOffsetFromExtraTargets += Offset;
			}
			IdealOffsetFromExtraTargets *= (ExtraTargetsWeight / ExtraFocusTargets.Num());

		}
		if (bSnap)
			ExtraFocusTargetOffset.SnapTo(IdealOffsetFromExtraTargets);
		else
			ExtraFocusTargetOffset.AccelerateTo(IdealOffsetFromExtraTargets, ExtraTargetsBlendTime, DeltaTime);
		FocusTarget.WorldOffset += ExtraFocusTargetOffset.Value;

		// Ignore extra targets height, just use max of players height
		FocusTarget.WorldOffset.Z = FMath::Max(CodyLoc.Z, MayLoc.Z);

		float ViewOffsetZ = FMath::Max3(
			FMath::Abs(ViewPlayer.ViewTransform.InverseTransformPosition(MayLoc).Z),
			FMath::Abs(ViewPlayer.ViewTransform.InverseTransformPosition(CodyLoc).Z),
			FMath::Abs(ViewPlayer.ViewTransform.InverseTransformPosition(MayLoc).Z));
		//PrintToScreenScaled("ViewOffsetZ: " + ViewOffsetZ);

		const float MaxViewOffset = 1600.f;
		float ViewOffsetPercentage = FMath::Clamp(ViewOffsetZ / MaxViewOffset, 0.f, 1.f);
		ViewOffsetPercentage = FMath::EaseInOut(0.f, 1.f, ViewOffsetPercentage, 1.4f);

		FocusTarget.ViewOffset = FVector(0.f, 0.f, ViewOffsetPercentage * -400.f);

		float MinDistance = FMath::Lerp(2250.f, 3500.f, ViewOffsetPercentage);
		FHazeCameraKeepInViewSettings Settings;
		Settings.bUseMinDistance = true;
		Settings.MinDistance = MinDistance;
		Settings.bUseAccelerationDuration = true;
		Settings.AccelerationDuration = 1.f;
		Settings.bUseBufferDistance = true;
		Settings.BufferDistance = 0.f;

		if (bSnap)
		{
			// Clear any other settings we may have set, the snap settings should be the new base line
			PlayerUser.ClearCameraSettingsByInstigator(this, 0.f);
			PlayerUser.ApplyCameraKeepInViewSettings(Settings, CameraBlend::Normal(0.f), this, EHazeCameraPriority::Medium);
		}
		else
		{
			PlayerUser.ApplyCameraKeepInViewSettings(Settings, CameraBlend::Normal(1.f), this, EHazeCameraPriority::High);
		}

		KeepInViewComp.SetPrimaryTarget(FocusTarget);
	}	
};


struct FExtraFocusTarget
{
	UPROPERTY()
	AHazeActor Target;
	UPROPERTY()
	float Weight = 0.5f;

	bool opEquals(AHazeActor OtherTarget)	
	{
		return Target == OtherTarget;
	}

	bool opEquals(FExtraFocusTarget OtherTarget)	
	{
		return Target == OtherTarget.Target;
	}
}