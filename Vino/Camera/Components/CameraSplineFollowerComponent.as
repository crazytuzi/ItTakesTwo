import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Components.CameraBlendToSplineComponent;

enum ESplineFollowType
{
	Weighted, // Follow weighted middle point of all follow targets
	Foremost, // Follow only the follow target which is furthest along the (guide) spline. Will ignore targets with weight 0.
	Rearmost, // Follow only the follow target which closest to the start of the (guide) spline. Will ignore targets with weight 0.
}

enum ESplineFollowClampType
{
	None,			// Do not tweak camera clamps
	Tangent,		// Any clamps are centered around spline tangent
	TangentLeft,	// Any clamps are centered around 90 degrees yaw to spline tangent left
	TangentRight,	// Any clamps are centered around 90 degrees yaw to spline tangent right
}

struct FSplineFollowTarget
{
	UPROPERTY()
	FHazeFocusTarget Target;

	UPROPERTY()
	float Weight = 0.f; 

	bool IsValid(bool bAllowDeadPlayers) const
	{
		if (Weight <= 0.f)
			return false;
		if (!Target.IsValid())
			return false;
		if (!bAllowDeadPlayers)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target.Actor);
			if ((Player != nullptr) && IsPlayerDead(Player))
				return false;
		}

		return true;
	}
}

void InitializeFollowTargets(const TArray<FSplineFollowTarget>& FollowTargets, const FSplineFollowTarget& UserFollowTarget, const FSplineFollowTarget& OtherPlayerFollowTarget, TArray<FSplineFollowTarget>& OutAllFollowTargets, bool& bOutFollowBothPlayers)
{
	OutAllFollowTargets = FollowTargets;
	if (UserFollowTarget.IsValid(true))
		OutAllFollowTargets.Add(UserFollowTarget);
	if (OtherPlayerFollowTarget.IsValid(true))
		OutAllFollowTargets.Add(OtherPlayerFollowTarget);

	bOutFollowBothPlayers = false;
	if (UserFollowTarget.IsValid(true) && OtherPlayerFollowTarget.IsValid(true))
	{
		bOutFollowBothPlayers = true;
	}
	else
	{
		AHazePlayerCharacter FollowPlayer = nullptr;
		for (FSplineFollowTarget FollowTarget : OutAllFollowTargets)
		{
			if (FollowTarget.Weight <= 0.f)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(FollowTarget.Target.Actor);
			if (Player != nullptr)
			{
				if (FollowPlayer == nullptr)
				{
					FollowPlayer = Player;
				}
				else if (FollowPlayer != Player)
				{
					// We have both players as focus targets
					bOutFollowBothPlayers = true;
					break;		
				}
			}
		}
	}
}

bool AreBothPlayersDead()
{
	return ((Game::GetMay() == nullptr) || IsPlayerDead(Game::GetMay())) && 
		   ((Game::GetCody() == nullptr) || IsPlayerDead(Game::GetCody()));
}

UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UCameraSplineFollowerComponent : UHazeCameraParentComponent
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

	// Use for a spline you should be able to follow in both directions. If true, this will invert backwards offset if that alings better with view direction when activating camera.
	UPROPERTY()
	bool bAlignBackwardsOffsetWithView = false;
	float BackwardsOffsetAlign = 1.f;

	// The higher the angle the more inclined we are to align with spline forward at start and backward at end. 
	UPROPERTY(meta = (EditCondition = "bAlignBackwardsOffsetWithView"))
	float BackwardsOffsetAlignAngle = 120.f;

	// If true, we will try to avoid collision with obstructions while blending in to spline.
	UPROPERTY()
	bool bObstructionAvoidanceBlend = false;

	// How do we choose which location we should follow?
	UPROPERTY()
	ESplineFollowType FollowType = ESplineFollowType::Weighted;

	// If true, we will follow dead players the same as alive ones. If false, we will only follow dead players if both players are dead.
	UPROPERTY()
	bool bAlwaysFollowDeadPlayers = false;
	bool bFollowBothPlayers = false;

	// Follow target for the player activating this camera
	UPROPERTY()
	FSplineFollowTarget UserFollowTarget;
	default UserFollowTarget.Weight = 1.f;

	// Follow target for the player not activating this camera
	UPROPERTY()
	FSplineFollowTarget OtherPlayerFollowTarget;

	// Additional follow targets
	UPROPERTY()
	TArray<FSplineFollowTarget> FollowTargets;

	// If not None any clamps of the camera will be modified according to this property
	UPROPERTY(AdvancedDisplay)
	ESplineFollowClampType ClampsModifier = ESplineFollowClampType::None;

	FHazeAcceleratedFloat DistanceAlongSpline;
	AHazePlayerCharacter PlayerUser = nullptr;
	TArray<FSplineFollowTarget> AllFollowTargets; // Includes player follow targets

	// These need to be properties so they get copied over to user specific copy
	UPROPERTY(Transient, NotVisible, BlueprintHidden)
	TArray<FSplineFollowTarget> PendingAddFollowTargets;
	UPROPERTY(Transient, NotVisible, BlueprintHidden)
	TArray<AActor> PendingRemoveFollowTargets;

#if EDITOR
	float PreviewSplineFraction = 0.f;
#endif

	//bool bDebugDraw = false;
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TemplateComponent != nullptr)
		{
			UCameraSplineFollowerComponent SplineFollowerTemplate = Cast<UCameraSplineFollowerComponent>(TemplateComponent);
			PendingAddFollowTargets.Append(SplineFollowerTemplate.PendingAddFollowTargets);
			PendingRemoveFollowTargets.Append(SplineFollowerTemplate.PendingRemoveFollowTargets);
		}
		else if (bObstructionAvoidanceBlend)
		{
			// TODO: We allow this for convenience in Nuts, but we should really have a separate 
			// actor with a blend to spline component in the attach chain instead.
			// Insert a blend to spline component between this an any attach children. 
			// Since this is done for the template component, it'll gte duplicated for player components as well.
			UCameraBlendToSplineComponent BlendToSplineComp = UCameraBlendToSplineComponent::Create(Owner, n"BlendToSpline");
			BlendToSplineComp.CameraSpline = CameraSpline;
			BlendToSplineComp.AttachToComponent(this);
			TArray<USceneComponent> Children;
			GetChildrenComponents(false, Children);
			for (USceneComponent Child : Children)
			{
				Child.AttachToComponent(BlendToSplineComp, AttachmentRule = EAttachmentRule::KeepRelative);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		// Ensure we have a guide spline
		if (GuideSpline == nullptr)
			GuideSpline = CameraSpline;

		// Add user and other player follow targets if appropriate.
		PlayerUser = Cast<AHazePlayerCharacter>(User.GetOwner());
		UserFollowTarget.Target.Actor = User.GetOwner();
		OtherPlayerFollowTarget.Target.Actor = (PlayerUser != nullptr) ? PlayerUser.GetOtherPlayer() : nullptr;

		// Handle dynamically added/removed focus targets now that we know who is user and other player
		for (FSplineFollowTarget& PendingAdd : PendingAddFollowTargets)
			AddFollowTargetInternal(PendingAdd);
		PendingAddFollowTargets.Empty();
		for (AActor PendingRemove : PendingRemoveFollowTargets)
			RemoveFollowTargetInternal(PendingRemove);
		PendingRemoveFollowTargets.Empty();

		InitializeFollowTargets(FollowTargets, UserFollowTarget, OtherPlayerFollowTarget, AllFollowTargets, bFollowBothPlayers);

		BackwardsOffsetAlign = GetBackWardsOffsetViewAlignment();

		if (PreviousState == EHazeCameraState::Inactive)
		{
			// Camera was not previously blending out or active, 
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
		
		FVector NewLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline.Value, ESplineCoordinateSpace::World);
		SetWorldLocation(NewLoc);

		if (ClampsModifier != ESplineFollowClampType::None)
		{
			FHazeCameraClampSettings Clamps = Camera.ClampSettings;
			ModifyClamps(DistanceAlongSpline.Value, Clamps);
			PlayerUser.ApplyCameraClampSettings(Clamps, FHazeCameraBlendSettings::Invalid, this, Camera.SettingsPriority);
		}
	}

	float GetTargetDistanceAlongSpline(UHazeCameraUserComponent User, bool bUseBackwardsOffset = true)
	{
		if (CameraSpline == nullptr)
			return 0.f;

		if (User.GetOwner() == nullptr)
			return 0.f;

		float Fraction = GetFollowFraction();
		float TargetDistance = Fraction * CameraSpline.GetSplineLength();
		if (bUseBackwardsOffset)
			TargetDistance -= (BackwardsOffset * BackwardsOffsetAlign);
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
		FVector Direction;
		if (ClampsModifier == ESplineFollowClampType::Tangent)
			Direction = CameraSpline.GetTangentAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
		else if (ClampsModifier == ESplineFollowClampType::TangentLeft)
			Direction = -GetUntwistedRightVector(DistAlongSpline);
		else if (ClampsModifier == ESplineFollowClampType::TangentRight)
			Direction = GetUntwistedRightVector(DistAlongSpline);

		InOutClamps.CenterType = EHazeCameraClampsCenterRotation::WorldSpace;
		InOutClamps.bUseCenterOffset = true;
		InOutClamps.CenterOffset = Direction.Rotation();	

		// FRotator AvgCenter = InOutClamps.CenterOffset;
		// AvgCenter.Yaw += 0.5f * (InOutClamps.ClampYawLeft + InOutClamps.ClampYawRight) - InOutClamps.ClampYawLeft;
		// Debug::DrawDebugArc(InOutClamps.ClampYawLeft + InOutClamps.ClampYawRight, 
		// CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World), 1000.f, 
		// AvgCenter.Vector(), FLinearColor::Green, 5.f, FVector::UpVector);	
	}	

	FVector GetUntwistedRightVector(float Dist)
	{
		FVector RightDir = CameraSpline.GetRightVectorAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World);

		// Splines can twist in unwanted ways which can be a hassle to edit, so we'll assume 
		// you never want roll to flip in between spline points with similar roll
		float PrevPointDist = 0.f;
		for (int i = 1; i < CameraSpline.GetNumberOfSplinePoints(); i++)
		{
			float NextPointDist = CameraSpline.GetDistanceAlongSplineAtSplinePoint(i);
			if (NextPointDist > Dist) // Note that this means NextPointDist > PrevPointDist
			{
				// Found current interval, check for twist
				FVector PrevRight = CameraSpline.GetRightVectorAtDistanceAlongSpline(PrevPointDist, ESplineCoordinateSpace::World);
				FVector NextRight = CameraSpline.GetRightVectorAtDistanceAlongSpline(NextPointDist, ESplineCoordinateSpace::World);
				if ((PrevRight.DotProduct(RightDir) < -0.87f) && (NextRight.DotProduct(RightDir) < -0.87f))
					return -RightDir; // We have a twist, use left dir
				return RightDir; // No twist, carry on!
			} 
			PrevPointDist = NextPointDist;
		}
		return RightDir; // At end
	}

	// Adds focus target for any camera used by given player (or all cameras if 'Both')
	UFUNCTION()
	void AddFollowTarget(FSplineFollowTarget FollowTarget, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UActorComponent> SplineFollowers = GetOwner().GetComponentsByClass(UCameraSplineFollowerComponent::StaticClass());
		for (UActorComponent Comp : SplineFollowers)
		{
			UCameraSplineFollowerComponent SplineFollower = Cast<UCameraSplineFollowerComponent>(Comp);
			if ((SplineFollower != nullptr) && SplineFollower.IsUsedByPlayer(AffectedPlayer))
				SplineFollower.AddFollowTargetInternal(FollowTarget);
		}
	}

	void AddFollowTargetInternal(const FSplineFollowTarget& FollowTarget)
	{
		if (FollowTarget.Target.Actor == nullptr)
			return;

		if (UserFollowTarget.Target.Actor == nullptr)
		{
			// We don't know who user or other player is yet, don't add until camera is activated
			PendingAddFollowTargets.Add(FollowTarget);
			PendingRemoveFollowTargets.Remove(FollowTarget.Target.Actor);	
			return;
		}
		
		// Only allow one target for each actor
		if (FollowTarget.Target.Actor == UserFollowTarget.Target.Actor)
			UserFollowTarget = FollowTarget;
		else if (FollowTarget.Target.Actor == OtherPlayerFollowTarget.Target.Actor)
			OtherPlayerFollowTarget = FollowTarget;
		else
		{
			bool bNewTarget = true;
			for (FSplineFollowTarget& Target : FollowTargets)
			{
				if (Target.Target.Actor == FollowTarget.Target.Actor)
				{
					bNewTarget = false;
					Target = FollowTarget;
					break;
				}
			}
			if (bNewTarget)
				FollowTargets.Add(FollowTarget);
		}

		if (Camera.GetCameraState() != EHazeCameraState::Inactive)
			InitializeFollowTargets(FollowTargets, UserFollowTarget, OtherPlayerFollowTarget, AllFollowTargets, bFollowBothPlayers);
	}

	// Adds focus target for any camera used by given player (or all cameras if 'Both')
	UFUNCTION()
	void RemoveFollowTarget(AActor FollowTarget, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UActorComponent> SplineFollowers = GetOwner().GetComponentsByClass(UCameraSplineFollowerComponent::StaticClass());
		for (UActorComponent Comp : SplineFollowers)
		{
			UCameraSplineFollowerComponent SplineFollower = Cast<UCameraSplineFollowerComponent>(Comp);
			if ((SplineFollower != nullptr) && SplineFollower.IsUsedByPlayer(AffectedPlayer))
				SplineFollower.RemoveFollowTargetInternal(FollowTarget);
		}
	}

	void RemoveFollowTargetInternal(AActor FollowedActor)
	{
		if (FollowedActor == nullptr)
			return;

		if (UserFollowTarget.Target.Actor == nullptr)
		{
			// We don't know who our user and other player will be yet, remove when activated instead
			PendingRemoveFollowTargets.Add(FollowedActor);
			for (int i = PendingAddFollowTargets.Num() - 1; i >= 0; i--)
			{
				if (PendingAddFollowTargets[i].Target.Actor == FollowedActor)
					PendingAddFollowTargets.RemoveAtSwap(i);	
			}
			return;
		}
		
		if (FollowedActor.IsA(AHazePlayerCharacter::StaticClass()))
			bFollowBothPlayers = false;

		// Remove any follow target with given actor
		if (UserFollowTarget.Target.Actor == FollowedActor)
			UserFollowTarget.Weight = 0.f;

		if (OtherPlayerFollowTarget.Target.Actor == FollowedActor)
			OtherPlayerFollowTarget.Weight = 0.f;

		for (int i = FollowTargets.Num() - 1; i >= 0; i--)
		{
			if (FollowTargets[i].Target.Actor == FollowedActor)
				FollowTargets.RemoveAtSwap(i);
		}

		if (Camera.GetCameraState() != EHazeCameraState::Inactive)
		{
			for (int i = AllFollowTargets.Num() - 1; i >= 0; i--)
			{
				if (AllFollowTargets[i].Target.Actor == FollowedActor)
					AllFollowTargets.RemoveAtSwap(i);
			}
		}
	}

	float GetBackWardsOffsetViewAlignment()
	{
		if (!bAlignBackwardsOffsetWithView)
			return 1.f;
		
		float DistAlongSpline = GetTargetDistanceAlongSpline(Camera.User, false);
		FVector SplineTangent = CameraSpline.GetTangentAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
		FVector ViewDir = PlayerUser.GetViewRotation().Vector();
		float Angle = FMath::Abs(FRotator::NormalizeAxis(BackwardsOffsetAlignAngle));
		float AlignDegrees = FMath::GetMappedRangeValueClamped(FVector2D(0.f, CameraSpline.SplineLength), FVector2D(Angle, 180.f - Angle), DistAlongSpline);
		if (ViewDir.DotProduct(SplineTangent.GetSafeNormal()) < FMath::Cos(FMath::DegreesToRadians(AlignDegrees)))
			return -1.f;
		return 1.f;
	}
};
