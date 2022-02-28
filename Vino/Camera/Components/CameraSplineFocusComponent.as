import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UCameraSplineFocusComponent : UHazeCameraParentComponent
{
    // The spline this component will rotate to look at
    UPROPERTY()
    UHazeSplineComponentBase FocusSpline = nullptr;

    // The spline against which we will check the followers location to see how far along the FocusSpline we should be.
    // If guide spline is null, the focus spline will be used as guide spline. 
    UPROPERTY()
    UHazeSplineComponentBase GuideSpline = nullptr;

    // How fast we move along the spline  
    UPROPERTY()
    float FollowSpeed = 1.f;

    // The camera is offset this many units behind the follow target along the camera spline.
    UPROPERTY()
    float BackwardsOffset = 0.f;

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

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (TemplateComponent != nullptr)
        {
            UCameraSplineFocusComponent SplineFollowerTemplate = Cast<UCameraSplineFocusComponent>(TemplateComponent);
            PendingAddFollowTargets.Append(SplineFollowerTemplate.PendingAddFollowTargets);
            PendingRemoveFollowTargets.Append(SplineFollowerTemplate.PendingRemoveFollowTargets);
        }

		// Never allow any parent spline follower to set clamps
		TArray<USceneComponent> ParentComps;
		GetParentComponents(ParentComps);
		for (USceneComponent Parent : ParentComps)
		{
			UCameraSplineFollowerComponent FollowerParent = Cast<UCameraSplineFollowerComponent>(Parent);
			if (FollowerParent != nullptr)
				FollowerParent.ClampsModifier = ESplineFollowClampType::None;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnAttachedCamera(UHazeCameraComponent AttachedCamera)
	{
		// Any clamps for camera should be focused around this component
		AttachedCamera.ClampSettings.CenterType = EHazeCameraClampsCenterRotation::Component;
		AttachedCamera.ClampSettings.CenterComponent = this; 
	}

    UFUNCTION(BlueprintOverride)
    void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
    {
        // Ensure we have a guide spline
        if (GuideSpline == nullptr)
            GuideSpline = FocusSpline;

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

        if (PreviousState == EHazeCameraState::Inactive)
        {
            // Camera was not previously blending out or active.
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
        if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (FocusSpline == nullptr))
            return;
        if (GuideSpline == nullptr)
            GuideSpline = FocusSpline;
        DistanceAlongSpline.Value = GetTargetDistanceAlongSpline(Camera.GetUser());
        DistanceAlongSpline.Velocity = 0.f;
        UpdateInternal(0.f);
    }
    UFUNCTION(BlueprintOverride)
    void Update(float DeltaSeconds)
    {
        if ((Camera == nullptr) || (Camera.GetUser() == nullptr) || (FocusSpline == nullptr))
            return;
        UpdateInternal(DeltaSeconds);
    }
    void UpdateInternal(float DeltaSeconds)
    {
        float SplineLength = FocusSpline.GetSplineLength();     
        float TargetDistAlongSpline = GetTargetDistanceAlongSpline(Camera.GetUser());
        if (FocusSpline.IsClosedLoop() && (FMath::Abs(TargetDistAlongSpline - DistanceAlongSpline.Value) > SplineLength * 0.5f))
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
        
        FVector FocusLoc = FocusSpline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline.Value, ESplineCoordinateSpace::World);
        SetWorldRotation((FocusLoc - WorldLocation).Rotation());    
    }
    float GetTargetDistanceAlongSpline(UHazeCameraUserComponent User)
    {
        if (FocusSpline == nullptr)
            return 0.f;
        if (User.GetOwner() == nullptr)
            return 0.f;
        float Fraction = GetFollowFraction();
        float TargetDistance = Fraction * FocusSpline.GetSplineLength();
        TargetDistance -= BackwardsOffset;
        if (!FocusSpline.IsClosedLoop())
            TargetDistance = FMath::Clamp(TargetDistance, 0.f, FocusSpline.GetSplineLength());
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
            //  System::DrawDebugLine(FolloweeLoc, FolloweeLoc + FVector(0,0, FollowTarget.Weight * 100), FLinearColor::Yellow, 0, 3);
        }
        if (WeightSum == 0.f)
            return 0.f;
        // if (bDebugDraw) 
        //  System::DrawDebugLine(LocationSum / WeightSum, LocationSum / WeightSum + FVector(0,0, WeightSum * 100), FLinearColor::Green, 0, 5);
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
        //  DebugDrawPositionalFollowTargets(ForemostFraction);
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
        return RearmostFraction;
    }
    // Adds focus target for any camera used by given player (or all cameras if 'Both')
    UFUNCTION()
    void AddFollowTarget(FSplineFollowTarget FollowTarget, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
    {
        if (AffectedPlayer == EHazeSelectPlayer::None)
            return;
        TArray<UActorComponent> SplineFollowers = GetOwner().GetComponentsByClass(UCameraSplineFocusComponent::StaticClass());
        for (UActorComponent Comp : SplineFollowers)
        {
            UCameraSplineFocusComponent SplineFollower = Cast<UCameraSplineFocusComponent>(Comp);
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
        TArray<UActorComponent> SplineFollowers = GetOwner().GetComponentsByClass(UCameraSplineFocusComponent::StaticClass());
        for (UActorComponent Comp : SplineFollowers)
        {
            UCameraSplineFocusComponent SplineFollower = Cast<UCameraSplineFocusComponent>(Comp);
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

	UFUNCTION()
	void SetBackwardsOffset(float Offset, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UActorComponent> Comps = GetOwner().GetComponentsByClass(UCameraSplineFocusComponent::StaticClass());
		for (UActorComponent Comp : Comps)
		{
			UCameraSplineFocusComponent SplineFocuser = Cast<UCameraSplineFocusComponent>(Comp);
			if ((SplineFocuser != nullptr) && SplineFocuser.IsUsedByPlayer(AffectedPlayer))
				SplineFocuser.BackwardsOffset = Offset;
		}
	}
};