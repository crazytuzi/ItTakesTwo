import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.Cymbal.CymbalFeature;
import Cake.LevelSpecific.Music.Cymbal.CymbalCrosshairWidget;
import Peanuts.Aiming.AutoAimStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalAimWidget;



UFUNCTION()
void SetCymbalVisible(bool bVisible)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());

	if(CymbalComp != nullptr)
		CymbalComp.SetCymbalVisible(bVisible);
}

void Local_SetCymbalVisible(bool bVisible)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::Cody);
	if(CymbalComp != nullptr)
		CymbalComp.Local_SetCymbalVisible(bVisible);
}

UCymbalSettings GetCymbalSettingsFromPlayer(AHazePlayerCharacter Player)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Player);

	if(CymbalComp != nullptr && CymbalComp.CymbalActor != nullptr)
	{
		return UCymbalSettings::GetSettings(CymbalComp.CymbalActor);
	}

	return nullptr;
}

bool IsPlayerAimingWithCymbal(AHazePlayerCharacter Player)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Player);

	if(CymbalComp != nullptr)
	{
		return CymbalComp.IsLookingForTarget();
	}

	return false;
}

UCymbalImpactComponent GetCymbalTarget(AHazePlayerCharacter Player)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Player);

	if(CymbalComp != nullptr)
	{
		if(CymbalComp.CymbalTrace.Actor != nullptr)
		{
			return UCymbalImpactComponent::Get(CymbalComp.CymbalTrace.Actor);

		}
	}

	return nullptr;
}

bool ThrowCymbalWithoutAim(AActor Owner)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

	if(CymbalComp != nullptr)
	{
		return CymbalComp.bThrowWithoutAim;
	}

	return false;
}

bool CymbalTrace(AHazePlayerCharacter Player, const UCymbalImpactComponent ImpactComponent, FHazeHitResult& OutResult)
{
	// Invalid
	if(ImpactComponent == nullptr)
		return false;

	// Invalid
	auto CymbalComp = UCymbalComponent::Get(Player);
	if(CymbalComp == nullptr)
		return false;
	
	// Auto aim trace override the regular trace
	auto AutoAimComp = UAutoAimTargetComponent::Get(ImpactComponent.Owner);
	if(AutoAimComp != nullptr && AutoAimComp.PlayerCanTarget(Player))
	{
		if(CymbalComp.AutoAimTrace.AutoAimedAtActor == ImpactComponent.Owner)
		{
			FVector ImpactPoint = ImpactComponent.GetTransformFor(Player).Location;
			FVector DirToPoint = (ImpactPoint - CymbalComp.GetTraceStartPoint()).GetSafeNormal();
			OutResult.OverrideFHitResult(FHitResult(ImpactComponent.Owner, nullptr, ImpactPoint, DirToPoint));
			return true;
		}
		
		// Already valid
		if(CymbalComp.CymbalTrace.Actor == ImpactComponent.Owner)
		{
			OutResult = CymbalComp.CymbalTrace;
			return true;
		}

		return false;
	}

	// Already valid
	if(CymbalComp.CymbalTrace.Actor == ImpactComponent.Owner)
	{
		OutResult = CymbalComp.CymbalTrace;
		return true;
	}

	// Don't have this on the cymbal yet
	// We require the component to be targeted
	//if(ImpactComponent.AttachmentMode == EVineAttachmentType::HitLocation)
	//	return false;

	const FVector TraceFrom = CymbalComp.GetTraceStartPoint();

	bool bDebug = false;
#if EDITOR
	bDebug = ImpactComponent.bHazeEditorOnlyDebugBool;
#endif

	// we store the current trace to the object
	FVector TraceTo = ImpactComponent.GetTransformFor(Player).Location;
	TraceTo += (TraceTo - TraceFrom).GetSafeNormal() * 25.f; // safeyty amount so we hit the shape
	CymbalComp.GetCymbalTrace(TraceFrom, TraceTo, OutResult, bDebug);
	if(OutResult.Actor != ImpactComponent.Owner)
		return false;

	return true;
}

UFUNCTION()
void ApplyCymbalSettings(UCymbalSettings Settings, UObject Instigator, EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay)
{
	ACymbal Cymbal = GetCymbalActor();

	if(Cymbal != nullptr)
	{
		Cymbal.ApplySettings(Settings, Instigator, Priority);
	}
}

UFUNCTION()
void ClearCymbalSettingsByInstigator(UObject Instigator)
{
	ACymbal Cymbal = GetCymbalActor();

	if(Cymbal != nullptr)
	{
		Cymbal.ClearSettingsByInstigator(Instigator);
	}
}

UFUNCTION(BlueprintPure)
bool DoesCymbalExist()
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());

	if(CymbalComp == nullptr)
		return false;

	return CymbalComp.CymbalActor != nullptr;
}

UFUNCTION(BlueprintPure)
ACymbal GetCymbalActor()
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Game::GetCody());

	if(!devEnsure(CymbalComp != nullptr, "No CymbalComponent found on Cody!"))
		return nullptr;

	ACymbal Cymbal = CymbalComp.CymbalActor;

	if(!devEnsure(Cymbal != nullptr, "The Cymbal does not seem to exist."))
		return nullptr;

	return Cymbal;
}

bool IsCymbalEquipped(AActor Owner)
{
	UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

	if(CymbalComp != nullptr)
	{
		return CymbalComp.bCymbalEquipped;
	}

	return false;
}

class UCymbalOffsetComponent : UHazeOffsetComponent
{

}

UCLASS(Abstract)
class UCymbalComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ACymbal> CymbalClass;

	UPROPERTY(EditDefaultsOnly, Category = Camera)
	protected UHazeCameraSpringArmSettingsDataAsset AimCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = Camera)
	protected UHazeCameraSpringArmSettingsDataAsset AltAimCameraSettings;

	private UHazeCameraSpringArmSettingsDataAsset CurrentAimCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset AimAirCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset ShieldCameraSettings;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset CymbalJog;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset CymbalStrafe;

	UPROPERTY(Category = Animation)
	UAnimSequence CymbalNoThrow;

	UPROPERTY()
	UNiagaraSystem ShieldBashImpactEffect;

	UPROPERTY(Category = ForceFeedback)
	UForceFeedbackEffect ThrowForceFeedback;

	UPROPERTY(Category = ForceFeedback)
	UForceFeedbackEffect CatchForceFeedback;

	UPROPERTY()
	UCymbalSettings FlyingCymbalSettings;

	FVector RelativeLocationOffset;
	FRotator RelativeRotationOffset;

	AHazePlayerCharacter Player;
	ACymbal CurrentCymbal = nullptr;
	UCymbalOffsetComponent CymbalOffsetComp = nullptr;

	UPROPERTY(Category = Movement)
	float AimLerpSpeed = 10.0f;

	UPROPERTY(Category = Movement)
	float ShieldRotationSpeed = 20.0f;

	UPROPERTY(NotEditable, BlueprintReadOnly, Category = Animation)
	float CurrentAimRotationSpeed = 0.0f;

	UPROPERTY(Category = Collision)
	ETraceTypeQuery CymbalTraceType;

	UPROPERTY(Category = Flying)
	UCymbalSettings FlyingSettings;
	UPROPERTY(Category = Flying)
	UCymbalSettings HoverSettings;

	FName BackSocket = n"Backpack";
	int CymbalSpawnCount = 0;

	// Duration that must elaps before being able to throw the cymbal again after having cought it.
	UPROPERTY()
	float ThrowCooldown = 0.35f;
	float ThrowCooldownElapsed = 0.0f;

	// Minimal duration that aiming will stay active after activation to avoid being able to spam it in and out.
	UPROPERTY()
	float AimCooldown = 0.35f;

	UCymbalImpactComponent CurrentTarget = nullptr;

	FAutoAimLine AutoAimTrace;
	FHazeHitResult CymbalTrace;
	bool bHasValidTarget = false;
	
	// For animation purpose
	UPROPERTY(BlueprintReadOnly)
	bool bAiming = false;

	private bool bLookingForTarget = false;
	bool IsLookingForTarget() const { return bLookingForTarget; }
	
	// Aiming needs to know if the Cymbal was thrown to re-attach it to the back, or not.
	bool bCymbalWasThrown = false;
	UPROPERTY()
	bool bThrowWithoutAim = false;
	bool bStartMoving = false;
	bool bCymbalWasCaught = false;	// Set from the Cymbal itself to notify the player that it should now play the catch animation.
	bool bTargeting = false;

	// For audio purposes
	TArray<AHazeActor> ShieldImpactingActors;
	bool bCymbalAudioOnFlying = false;

	void OffsetCymbal()
	{
		const float OffsetTime = 0.5f;
		CymbalOffsetComp.OffsetRelativeLocationWithTime(RelativeLocationOffset, OffsetTime);
		CymbalOffsetComp.OffsetRelativeRotationWithTime(RelativeRotationOffset, OffsetTime);
	}

	void ResetOffset(float OffsetTime = 0.15f)
	{
		CymbalOffsetComp.ResetRelativeLocationWithTime(OffsetTime);
		CymbalOffsetComp.ResetRelativeRotationWithTime(OffsetTime);
	}

	void SetCymbalOffset(FVector InCymbalLocationOffset, FRotator InCymbalRotationOffset)
	{
		RelativeLocationOffset = InCymbalLocationOffset;
		RelativeRotationOffset = InCymbalRotationOffset;
		if(bCymbalEquipped)
			OffsetCymbal();
	}

	void ResetCymbalOffsetValue(float OffsetTime = 0.15f)
	{
		RelativeLocationOffset = FVector::ZeroVector;
		RelativeRotationOffset = FRotator::ZeroRotator;
		ResetOffset(OffsetTime);
	}

	void SetEnableSlowMotionWhenAiming(bool bEnableSlowMo)
	{
		EnableSlowMotionWhenAimingCounter = (bEnableSlowMo ? EnableSlowMotionWhenAimingCounter + 1 : EnableSlowMotionWhenAimingCounter - 1);
	}

	void ApplyFlyingSettings(UObject Instigator)
	{
		if(CurrentCymbal == nullptr)
		{
			return;
		}

		CurrentCymbal.ApplySettings(FlyingSettings, Instigator);
	}

	void ClearFlyingSettings(UObject Instigator)
	{
		if(CurrentCymbal == nullptr)
		{
			return;
		}

		CurrentCymbal.ClearSettingsWithAsset(FlyingSettings, Instigator);
	}

	void ApplyHoverSettings(UObject Instigator)
	{
		if(CurrentCymbal == nullptr)
		{
			return;
		}

		CurrentCymbal.ApplySettings(HoverSettings, Instigator);
	}

	void ClearHoverSettings(UObject Instigator)
	{
		if(CurrentCymbal == nullptr)
		{
			return;
		}

		CurrentCymbal.ClearSettingsWithAsset(HoverSettings, Instigator);
	}

	FVector GetTraceStartPoint() const property
	{
		FVector TraceFrom = Player.ViewLocation;
		TraceFrom += Player.ViewRotation.ForwardVector * TraceFrom.Dist2D(Player.GetActorLocation(), Player.GetMovementWorldUp());
		return TraceFrom;
	}

	void ApplyCymbalAimCameraSetting()
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.5f;
		Player.ApplyCameraSettings(CurrentAimCameraSettings, Blend, this, EHazeCameraPriority::High);
	}

	void ClearCymbalAimCameraSetting()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	void SwapCameraAimSettings()
	{
		ClearCymbalAimCameraSetting();
		if(CurrentAimCameraSettings == AimCameraSettings)
			CurrentAimCameraSettings = AltAimCameraSettings;
		else
			CurrentAimCameraSettings = AimCameraSettings;
		ApplyCymbalAimCameraSetting();
	}
/*
	UHazeCameraSpringArmSettingsDataAsset GetCymbalAimCameraSettings() const property
	{
		return CurrentAimCameraSettings;
	}
*/
	UFUNCTION(BlueprintPure)
	ACymbal GetCymbalActor() const property { return CurrentCymbal; }

	bool IsSlowMotionWhenAimingEnabled() const { return EnableSlowMotionWhenAimingCounter > 0; }
	private int EnableSlowMotionWhenAimingCounter = 1;

	UPROPERTY(BlueprintReadOnly)
	bool bShieldActive = false;

	UPROPERTY(BlueprintReadOnly)
	bool bCymbalEquipped = true;

	void BlockCatchAnimation() { BlockCatchAnimationCounter++; }
	void UnblockCatchAnimation() { BlockCatchAnimationCounter--; }

	bool ShouldPlayCatchAnimation() const { return BlockCatchAnimationCounter <= 0; }

	private int BlockCatchAnimationCounter = 0;

	bool GetCanAttachToObjects() const property
	{
		return CurrentCymbal != nullptr ? CurrentCymbal.bCanAttachToObjects : false;
	}

	void SetCanAttachToObjects(bool bValue) property
	{
		if(CurrentCymbal != nullptr)
		{
			CurrentCymbal.bCanAttachToObjects = bValue;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentAimCameraSettings = AimCameraSettings;
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.AddLocomotionAsset(CymbalJog, this);

		CymbalOffsetComp = UCymbalOffsetComponent::GetOrCreate(Player);
		

		CurrentCymbal = Cast<ACymbal>(SpawnPersistentActor(CymbalClass));
		CymbalSpawnCount++;
		CurrentCymbal.MakeNetworked(this, CymbalSpawnCount);
		CurrentCymbal.SetControlSide(Owner);
		CurrentCymbal.OwnerPlayer = Player;
		CurrentCymbal.SetOwner(Player);
		CurrentCymbal.AddCymbalCapabilities();
		CurrentCymbal.AttachToComponent(CymbalOffsetComp);
		
		SetCymbalOutlineVisibility(true);
		AttachCymbalToBack();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		CurrentCymbal.DestroyActor();
		CurrentCymbal = nullptr;

		if(CymbalOffsetComp != nullptr)
		{
			CymbalOffsetComp.DestroyComponent(Player);
			CymbalOffsetComp = nullptr;
		}
	}

	UFUNCTION()
	void SetCymbalVisible(bool bVisible) property
	{
		NetSetCymbalVisible(bVisible);
	}

	void Local_SetCymbalVisible(bool bVisible)
	{
		if(CymbalActor != nullptr)
			CymbalActor.SetActorHiddenInGame(!bVisible);
	}

	void GetCymbalTrace(FVector From, FVector To, FHazeHitResult& OutResult, bool bWithDebug) const
	{
		TArray<AActor> ActorsToIgnore;	
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(CymbalTraceType);
		Trace.IgnoreActors(ActorsToIgnore);
		Trace.From = From;
		Trace.To = To;
		Trace.DebugDrawTime = bWithDebug ? 0.f : -1.f;
		Trace.SetToLineTrace();

		Trace.Trace(OutResult);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetSetCymbalVisible(bool bValue)
	{
		if(CymbalActor != nullptr)
			CymbalActor.SetActorHiddenInGame(!bValue);
	}

	void SetCymbalOutlineVisibility(bool bShowOutline)
	{
		if (bShowOutline)
			CurrentCymbal.CymbalMesh.AddMeshToPlayerOutline(Player, this);
		else
			RemoveMeshFromPlayerOutline(CurrentCymbal.CymbalMesh, this);
	}

	void StartAiming()
	{

	}

	void StopAiming()
	{

	}

	void AttachCymbalToBack()
	{
		AttachCymbalToSocket(BackSocket);
		bCymbalEquipped = true;
		Player.SetCapabilityActionState(n"AudioUnequipCymbal", EHazeActionState::ActiveForOneFrame);
		OffsetCymbal();
	}

	void AttachCymbalToSocket(FName SocketName)
	{
		DetachCymbalFromPlayer();
		//CurrentCymbal.SetActorLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		CurrentCymbal.SetActorRelativeTransform(FTransform::Identity);
		CurrentCymbal.AttachToComponent(CymbalOffsetComp);
		CymbalOffsetComp.AttachToComponent(Player.Mesh, SocketName, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		//CurrentCymbal.AttachToComponent(CymbalOffsetComp, SocketName, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		CurrentCymbal.CymbalMesh.RelativeRotation = FRotator::ZeroRotator;
		CurrentCymbal.CymbalMesh.RelativeLocation = FVector::ZeroVector;
		CurrentCymbal.RootComp.RelativeLocation = FVector::ZeroVector;
	}

	void AttachCymbalToHands()
	{
		AttachCymbalToSocket(n"Backpack");
	}

	void ThrowCymbal()
	{
		devEnsure(CymbalActor != nullptr);
		SetCymbalOutlineVisibility(false);
		bCymbalEquipped = false;
	}

	void DetachCymbalFromPlayer()
	{
		CymbalActor.DetachRootComponentFromParent();
		/*if(CymbalActor.IsAtta IsAttachedTo(CymbalOffsetComp))
		{
			CymbalOffsetComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}
		else
			PrintToScreen("FAILED!", 2);*/
	}

	void CatchCymbal()
	{
		bCymbalEquipped = true;
		Player.PlayForceFeedback(CatchForceFeedback, false, true, NAME_None);
		SetCymbalOutlineVisibility(true);
		AttachCymbalToBack();
	}

	void ActivateShield()
	{
		AttachCymbalToSocket(n"Backpack");
	}

	void StartShielding()
	{
		bShieldActive = true;
	}

	void StopShielding()
	{
		bShieldActive = false;
	}

	void ApplyShieldCameraSettings()
	{
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 1.f;
		Player.ApplyCameraSettings(ShieldCameraSettings, CamBlend, this, EHazeCameraPriority::High);
	}

	void ClearShieldCameraSettings()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.f);
	}

	void RecallCymbal()
	{
		if(CurrentCymbal != nullptr)
		{
			//CurrentCymbal.CymbalState = ECymbalState::ReturnToOwner;
		}
	}

	void ShowEffect()
	{
		
	}

	void HideEffect()
	{
		
	}

	bool IsOverlappingWithOwningPlayer() const
	{
		devEnsure(CymbalActor != nullptr);
		return CymbalActor.IsOverlappingOwnerPlayer();
	}
}
