import Vino.PlayerHealth.PlayerHealthStatics;

struct FFocusTrackerTarget
{
    UPROPERTY(Category = "CameraFocus")
    FHazeFocusTarget Focus;

    UPROPERTY(Category = "CameraFocus")
    float Weight = 1.f;

    bool IsValid(bool bAllowDeadPlayers) const
    {
		if (Weight <= 0.f)
			return false;
        if (!Focus.IsValid())
			return false;
		if (!bAllowDeadPlayers) 
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Focus.Actor);
			if ((Player != nullptr) && IsPlayerDead(Player))
				return false;
		}
		return true;
    }
}

UCLASS(HideCategories="Activation Physics LOD AssetUserData Collision Rendering Cooking")
class UFocusTrackerComponent : UHazeCameraParentComponent
{
	UPROPERTY()
	float RotationSpeed = 10.f;

    UPROPERTY(BluePrintReadOnly)
    FFocusTrackerTarget UserFocus;
    default UserFocus.Focus.Actor = nullptr;
    default UserFocus.Weight = 1.f;

    UPROPERTY(BluePrintReadOnly)
    FFocusTrackerTarget OtherPlayerFocus;
    default OtherPlayerFocus.Focus.Actor = nullptr;
    default OtherPlayerFocus.Weight = 0.f;

	// If true, we will look at dead players the same as alive ones. If false, we will only look at dead players if both players are dead.
	UPROPERTY()
	bool bAlwaysFollowDeadPlayers = false;
	bool bBothPlayerFocus = true;

    UPROPERTY(BluePrintReadOnly)
    TArray<FFocusTrackerTarget> FocusTargets;

    FRotator PreviousWorldRotation;
    UHazeActiveCameraUserComponent User = nullptr;
	AHazePlayerCharacter PlayerUser = nullptr;
    TArray<FFocusTrackerTarget> AllFocusTargets;

	// These need to be properties so they get copied over to user specific copy
	UPROPERTY(NotVisible, BlueprintHidden)
	TArray<FFocusTrackerTarget> PendingAddFocusTargets;
	UPROPERTY(NotVisible, BlueprintHidden)
	TArray<AActor> PendingRemoveFocusTargets;
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousWorldRotation = GetWorldRotation();
		if (TemplateComponent != nullptr)
		{
			UFocusTrackerComponent FocusTrackerTemplate = Cast<UFocusTrackerComponent>(TemplateComponent);
			PendingAddFocusTargets.Append(FocusTrackerTemplate.PendingAddFocusTargets);
			PendingRemoveFocusTargets.Append(FocusTrackerTemplate.PendingRemoveFocusTargets);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
        PreviousWorldRotation = GetWorldRotation();

        User = Cast<UHazeActiveCameraUserComponent>(_User);
        AActor UserOwner = _User.GetOwner();
        UserFocus.Focus.Actor = UserOwner;
        PlayerUser = Cast<AHazePlayerCharacter>(UserOwner);
        AHazePlayerCharacter OtherPlayer = (PlayerUser != nullptr) ? PlayerUser.GetOtherPlayer() : nullptr;
        OtherPlayerFocus.Focus.Actor = OtherPlayer;

		// Handle dynamically added/removed focus targets now that we know who is user and other player
		for (FFocusTrackerTarget& PendingAdd : PendingAddFocusTargets)
			AddFocusTargetInternal(PendingAdd);
		PendingAddFocusTargets.Empty();
		for (AActor PendingRemove : PendingRemoveFocusTargets)
			RemoveFocusTargetInternal(PendingRemove);
		PendingRemoveFocusTargets.Empty();

		InitializeFocusTargets();

		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

    UFUNCTION(BlueprintOverride)
    void Snap()
    {
        if (User == nullptr)
            return;

        PreviousWorldRotation = GetTargetRotation();
        UpdateInternal(0.f);
    }

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
        if (User == nullptr)
            return;

        UpdateInternal(DeltaSeconds);
    }   

    void UpdateInternal(float DeltaSeconds)
    {
        FRotator ToFocusRot = GetTargetRotation();
        ToFocusRot = ClampRotation(ToFocusRot);
		FRotator NewRot = FMath::RInterpTo(PreviousWorldRotation, ToFocusRot, DeltaSeconds, RotationSpeed);
        SetWorldRotation(NewRot);
		PreviousWorldRotation = GetWorldRotation();
    }

    FRotator GetTargetRotation()
    {
        FVector BaseLocation = GetWorldLocation();
        FVector FocusOffset = FVector::ZeroVector;

		// If both players are dead, we allow them as focus targets
		bool bLookAtDeadPlayers = bAlwaysFollowDeadPlayers || !bBothPlayerFocus ||
								  (((Game::GetMay() == nullptr) || IsPlayerDead(Game::GetMay())) && 
								   ((Game::GetCody() == nullptr) || IsPlayerDead(Game::GetCody())));

        for (const FFocusTrackerTarget FocusTarget : AllFocusTargets)
        {
            if (FocusTarget.IsValid(bLookAtDeadPlayers))
            {
                FVector FocusLoc = FocusTarget.Focus.GetFocusLocation(PlayerUser);
                FocusOffset += (FocusLoc - BaseLocation) * FocusTarget.Weight;
            }
        }
        if (FocusOffset.IsNearlyZero())
		{
			// No focii (or we're on top of focus), use parent rotation
			USceneComponent Parent = GetAttachParent();
			if (Parent != nullptr)
				return Parent.GetWorldRotation();
            return GetWorldRotation();
		}
        return FocusOffset.ToOrientationRotator();
    }

    FRotator ClampRotation(const FRotator& Rotator)
    {
        FRotator LocalRot = User.WorldToLocalRotation(Rotator);
     	FHazeCameraClampSettings Clamps;
		if (User.GetClamps(Clamps))
        {
			if (Clamps.bUseClampPitchDown || Clamps.bUseClampPitchUp)
				LocalRot.Pitch = FMath::ClampAngle(LocalRot.Pitch, Clamps.CenterOffset.Pitch - Clamps.ClampPitchDown, Clamps.CenterOffset.Pitch + FMath::Min(Clamps.ClampPitchUp, 179.9f));
			if (Clamps.bUseClampYawLeft || Clamps.bUseClampYawLeft)
				LocalRot.Yaw = FMath::ClampAngle(LocalRot.Yaw, Clamps.CenterOffset.Yaw - FMath::Min(Clamps.ClampYawLeft, 179.9f), Clamps.CenterOffset.Yaw + FMath::Min(Clamps.ClampYawRight, 179.9f));
        }
        LocalRot.Roll = 0.f;

        return User.LocalToWorldRotation(LocalRot);
    }

	// Adds focus target for any camera used by given player (or all cameras if 'Both')
	UFUNCTION()
	void AddFocusTarget(FFocusTrackerTarget FocusTarget, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UActorComponent> FocusTrackers = GetOwner().GetComponentsByClass(UFocusTrackerComponent::StaticClass());
		for (UActorComponent Comp : FocusTrackers)
		{
			UFocusTrackerComponent FocusTracker = Cast<UFocusTrackerComponent>(Comp);
			if ((FocusTracker != nullptr) && FocusTracker.IsUsedByPlayer(AffectedPlayer))
				FocusTracker.AddFocusTargetInternal(FocusTarget);
		}
	}

	void AddFocusTargetInternal(FFocusTrackerTarget FocusTarget)
	{
		if (FocusTarget.Focus.Actor == nullptr)
			return;

		if (UserFocus.Focus.Actor == nullptr)
		{
			// We don't know who user or other player is yet, don't add until camera is activated
			PendingAddFocusTargets.Add(FocusTarget);
			PendingRemoveFocusTargets.Remove(FocusTarget.Focus.Actor);	
			return;
		}

		// Only allow one target for each actor
		if (UserFocus.Focus.Actor == FocusTarget.Focus.Actor)
			UserFocus = FocusTarget;
		else if (OtherPlayerFocus.Focus.Actor == FocusTarget.Focus.Actor)
			OtherPlayerFocus = FocusTarget;
		else
		{
			bool bNewTarget = true;
			for (FFocusTrackerTarget& Target : FocusTargets)
			{
				if (Target.Focus.Actor == FocusTarget.Focus.Actor)
				{
					bNewTarget = false;
					Target = FocusTarget;
					break;
				}
			}
			if (bNewTarget)
				FocusTargets.Add(FocusTarget);
		}

		if (Camera.GetCameraState() != EHazeCameraState::Inactive)
			InitializeFocusTargets();
	}

	// Removes focus target for any camera used by given player (or all cameras if 'Both')
	UFUNCTION()
	void RemoveFocusTarget(AActor FocusActor, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		if (AffectedPlayer == EHazeSelectPlayer::None)
			return;

        TArray<UActorComponent> FocusTrackers = GetOwner().GetComponentsByClass(UFocusTrackerComponent::StaticClass());
		for (UActorComponent Comp : FocusTrackers)
		{
			UFocusTrackerComponent FocusTracker = Cast<UFocusTrackerComponent>(Comp);
			if ((FocusTracker != nullptr) && FocusTracker.IsUsedByPlayer(AffectedPlayer))
				FocusTracker.RemoveFocusTargetInternal(FocusActor);
		}
	}

	void RemoveFocusTargetInternal(AActor FocusActor)
	{
		if (FocusActor == nullptr)
			return;

		if (UserFocus.Focus.Actor == nullptr)
		{
			// We don't know who our user and other player will be yet, remove when activated instead
			PendingRemoveFocusTargets.Add(FocusActor);
			for (int i = PendingAddFocusTargets.Num() - 1; i >= 0; i--)
			{
				if (PendingAddFocusTargets[i].Focus.Actor == FocusActor)
					PendingAddFocusTargets.RemoveAtSwap(i);	
			}
			return;
		}

		if (FocusActor.IsA(AHazePlayerCharacter::StaticClass()))
			bBothPlayerFocus = false;

		// Remove any follow target with given actor
		if (UserFocus.Focus.Actor == FocusActor)
			UserFocus.Weight = 0.f;

		if (OtherPlayerFocus.Focus.Actor == FocusActor)
			OtherPlayerFocus.Weight = 0.f;

		for (int i = FocusTargets.Num() - 1; i >= 0; i--)
		{
			if (FocusTargets[i].Focus.Actor == FocusActor)
				FocusTargets.RemoveAtSwap(i);
		}

		if (Camera.GetCameraState() != EHazeCameraState::Inactive)
		{
			for (int i = AllFocusTargets.Num() - 1; i >= 0; i--)
			{
				if (AllFocusTargets[i].Focus.Actor == FocusActor)
					AllFocusTargets.RemoveAtSwap(i);
			}
		}
	}

	void InitializeFocusTargets()
	{
		AllFocusTargets = FocusTargets;
		if (UserFocus.IsValid(true))
			AllFocusTargets.Add(UserFocus);
		if (OtherPlayerFocus.IsValid(true))
			AllFocusTargets.Add(OtherPlayerFocus);

		bBothPlayerFocus = false;
		if (UserFocus.IsValid(true) && OtherPlayerFocus.IsValid(true))
		{
			bBothPlayerFocus = true;
		}
		else
		{
			AHazePlayerCharacter FocusPlayer = nullptr;
			for (FFocusTrackerTarget FocusTarget : AllFocusTargets)
			{
				if (FocusTarget.Weight <= 0.f)
					continue;
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(FocusTarget.Focus.Actor);
				if (Player != nullptr)
				{
					if (FocusPlayer == nullptr)
					{
						FocusPlayer = Player;
					}
					else if (FocusPlayer != Player)
					{
						// We have both players as focus targets
						bBothPlayerFocus = true;
						break;		
					}
				}
			}
		}
	}
}