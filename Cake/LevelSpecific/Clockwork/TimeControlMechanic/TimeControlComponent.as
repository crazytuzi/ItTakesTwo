import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.CodyTimeControlWatch;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Vino.Checkpoints.Statics.DeathStatics;

bool CanActivateTimeComponent(AHazePlayerCharacter Player, const UTimeControlActorComponent ActorTimeComp)
{
	UTimeControlComponent PlayerTimeComp = UTimeControlComponent::Get(Player);
	if (ActorTimeComp.IsTimeControlDisabled())
		return false;
	return true;
}

void OnTimeComponentCameraSettingsChanged(UTimeControlActorComponent TimeComp)
{
	for (auto Player : Game::Players)
	{
		UTimeControlComponent Comp = UTimeControlComponent::Get(Player);
		if (Comp == nullptr)
			continue;

		auto CurrentControl = Comp.GetLockedOnComponent();
		if (CurrentControl == TimeComp)
		{
			if (Comp.bCameraSettingsActive)
				Comp.ReApplyCameraSettings();
		}
	}
}

UFUNCTION(Category = "Time Control Ability")
void SetTimeControlForcedActive(AHazePlayerCharacter Player, AActor ForcedActor)
{
	UTimeControlComponent TimeComp = UTimeControlComponent::Get(Player);
	if (ForcedActor != nullptr)
		TimeComp.ForcedTimeControlComponent = UTimeControlActorComponent::Get(ForcedActor);
	else
		TimeComp.ForcedTimeControlComponent = nullptr;
}

UFUNCTION(Category = "Time Control Ability")
ACodyTimeControlWatch GetTimeControlWatch(AHazePlayerCharacter Player)
{
	auto Comp = UTimeControlComponent::Get(Player);
	if (Comp != nullptr)
		return Comp.SpawnedTimeControlWatch;
	return nullptr;
}

class UTimeControlComponent : UActorComponent
{
	UPROPERTY(Category = "Time")
	UHazeCameraSettingsDataAsset CameraSettings = Asset("/Game/Blueprints/LevelSpecific/Clockwork/CameraSettings/DA_CamSettings_TimeControlAbility.DA_CamSettings_TimeControlAbility");

	UPROPERTY()
	UMaterialParameterCollection WorldShaderParameters = Asset("/Game/MasterMaterials/WorldParameters/WorldParameters.WorldParameters");

	UPROPERTY()
	UNiagaraParameterCollection WorldNiagaraParameters = Asset("/Game/MasterMaterials/WorldParameters/NiagaraWorldParameters.NiagaraWorldParameters");

	UPROPERTY()
	UHazeLocomotionFeatureBase TimeControlFeature;

	UPROPERTY(Category = "Time")
	TSubclassOf<UTimeControlAbilityWidget> TimeWidgetClass;	

	UPROPERTY(Category = "Time|Control")
	UNiagaraSystem TimeControlBeamAsset;

	UPROPERTY(Category = "Time|Control")
	TSubclassOf<ACodyTimeControlWatch> TimeControlWatch;
	
	UPROPERTY()
	ACodyTimeControlWatch SpawnedTimeControlWatch = nullptr;

	UNiagaraComponent TimeControlBeamComponent;

	UTimeControlAbilityWidget TimeWidget;
	
	TArray<FHitResult> HitResultsArray;

	bool bShouldNotTrace = false;

	bool bIsPlayingBlendSpace = false;

	FVector BeamTargetLocation;

	bool bHasPoi = false;
	bool bCameraSettingsActive = false;

	float CurrentTimeOffset = -1.0f;
	float TargetTimeOffset = -1.0f;
	
	AHazePlayerCharacter PlayerOwner;
	UTimeControlActorComponent ForcedTargetComponent;
	UTimeControlActorComponent ForcedTimeControlComponent;
	UTimeControlActorComponent ActiveTimeControlComponent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TimeWidget = Cast<UTimeControlAbilityWidget>(PlayerOwner.AddWidgetToHUDSlot(n"LevelAbility", TimeWidgetClass));
		TimeWidget.SetWidgetPersistent(true);

		SpawnedTimeControlWatch = Cast<ACodyTimeControlWatch>(SpawnPersistentActor(TimeControlWatch, PlayerOwner.GetActorLocation(), FRotator::ZeroRotator));
		SpawnedTimeControlWatch.AttachToActor(PlayerOwner, n"Backpack");
		SpawnedTimeControlWatch.SetActorRelativeTransform(SpawnedTimeControlWatch.BackpackAttachOffset);

		TimeControlBeamComponent = Niagara::SpawnSystemAttached(TimeControlBeamAsset, SpawnedTimeControlWatch.RootComponent, n"None", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
		TimeControlBeamComponent.Deactivate();
		Reset::RegisterPersistentComponent(TimeControlBeamComponent);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(SpawnedTimeControlWatch != nullptr)
		{
			SpawnedTimeControlWatch.DestroyActor();
			SpawnedTimeControlWatch = nullptr;
		}

		if (TimeControlBeamComponent != nullptr)
		{
			Reset::UnregisterPersistentComponent(TimeControlBeamComponent);
			TimeControlBeamComponent.DestroyComponent(TimeControlBeamComponent);
		}

		if (TimeWidget != nullptr)
			PlayerOwner.RemoveWidgetFromHUD(TimeWidget);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		auto TargetComponent = GetCurrentTargetComponent();
		
		if(TargetComponent != nullptr)
		{
			if(TargetComponent.IsTimeReversing())
			{
				TargetTimeOffset = -1.0f;
			}
			else if(TargetComponent.IsTimeProgressing())
			{
				TargetTimeOffset = 1.0f;
			}
		}

		CurrentTimeOffset = FMath::Lerp(CurrentTimeOffset, TargetTimeOffset, DeltaTime * 4.0f);
		SetUnwitherAndTimeWarpParameters(Owner.GetActorLocation(), 800.0f, CurrentTimeOffset);
	}

	UTimeControlActorComponent GetCurrentTargetComponent()const
	{
		if (ForcedTimeControlComponent != nullptr)
			return ForcedTimeControlComponent;
		if (ForcedTargetComponent != nullptr)
			return ForcedTargetComponent;
		return Cast<UTimeControlActorComponent>(PlayerOwner.GetTargetPoint(UTimeControlActorComponent::StaticClass()));		
	}

	UTimeControlActorComponent GetLockedOnComponent() const property
	{
		return ActiveTimeControlComponent;
	}

	UFUNCTION(BlueprintPure)
	float GetActiveTimeControlProgress() const
	{
		UTimeControlActorComponent Target = GetLockedOnComponent();
		if (Target == nullptr)
			return -1.f;
		return Target.GetPointInTime();
	}

	UFUNCTION(BlueprintPure)
	bool IsActiveTimeControlMoving() const
	{
		UTimeControlActorComponent Target = GetLockedOnComponent();
		if (Target == nullptr)
			return false;
		return Target.IsTimeMoving();
	}

	UFUNCTION(BlueprintPure)
	bool IsTimeControlActive() const
	{
		return GetLockedOnComponent() != nullptr;
	}

	UFUNCTION(BlueprintPure)
	float GetPitchAngleTowardsActiveTimeControl() property
	{
		FRotator Rotator = FRotator::MakeFromX(GetActiveTimeControlTargetDirection());
		return Rotator.Pitch;
	}

	FVector GetActiveTimeControlTargetDirection() const property
	{
		UTimeControlActorComponent Target = GetLockedOnComponent();
		if (Target == nullptr)
			return FVector::ForwardVector;
		FVector TargetPoint = Target.WorldTransform.TransformPosition(Target.PointOfInterestOffset.Location);
		return (TargetPoint - Owner.ActorLocation).GetSafeNormal();
	}

	void ActivatedAbility(UTimeControlActorComponent TargetedComponent, UHazeCapability Instigator)
	{	
		UTimeControlActorComponent ComponentToOperateOn = TargetedComponent;
		if(TargetedComponent.LinkedMaster != nullptr)
		{
			ComponentToOperateOn = UTimeControlActorComponent::Get(TargetedComponent.LinkedMaster); 
		}

		if(ComponentToOperateOn.bCanBeTimeControlled)
		{
			PlayerOwner.ActivatePoint(ComponentToOperateOn, Instigator);
			ActiveTimeControlComponent = ComponentToOperateOn;
			TimeWidget.ActivatedTimeControlAbility(TargetedComponent.WorldLocation); // The target component is the real component
			ComponentToOperateOn.ActivateTimeControl();
			TimeWidget.SetTimeWidgetVisible(true);

			auto ClosestCamera = ActiveTimeControlComponent.GetStaticCamera(PlayerOwner);
			if (ClosestCamera != nullptr)
				ClosestCamera.ActivateCamera(PlayerOwner, ActiveTimeControlComponent.ControlCameraSettingsBlendTime, this);
		}
	}

	void DeactiveAbility(UHazeCapability Instigator)
	{
		UTimeControlActorComponent TimeComp = GetLockedOnComponent();
		if(TimeComp != nullptr)
		{
			PlayerOwner.DeactivateCurrentPoint(Instigator);
			ActiveTimeControlComponent = nullptr;
			TimeComp.DeactivateAbility();
			PlayerOwner.DeactivateCameraByInstigator(this, TimeComp.ControlCameraSettingsBlendOutTime);
		}
		else
		{
			PlayerOwner.DeactivateCameraByInstigator(this);
		}

		TimeControlBeamComponent.Deactivate();
		TimeWidget.SetTimeWidgetVisible(false);
	}

	void ReApplyCameraSettings()
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 3.f;

		UHazeCameraSettingsDataAsset Settings = CameraSettings;

		auto TargetComponent = GetLockedOnComponent();
		if (TargetComponent.ControlCameraSettings != nullptr)
		{
			Settings = TargetComponent.ControlCameraSettings;
			Blend.BlendTime = TargetComponent.ControlCameraSettingsBlendTime;
		}

		PlayerOwner.ClearCameraSettingsByInstigator(this, Blend.BlendTime);
		if (Settings != nullptr)
			PlayerOwner.ApplyCameraSettings(Settings, Blend, this, EHazeCameraPriority::High);
	}

	void SetCameraSettingsEnabled(UTimeControlActorComponent TargetComponent, bool bEnabled)
	{
		if (bEnabled)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 3.f;

			UHazeCameraSettingsDataAsset Settings = CameraSettings;

			if (TargetComponent.ControlCameraSettings != nullptr)
			{
				Settings = TargetComponent.ControlCameraSettings;
				Blend.BlendTime = TargetComponent.ControlCameraSettingsBlendTime;
			}

			PlayerOwner.ApplyCameraSettings(Settings, Blend, this, EHazeCameraPriority::High);
			bCameraSettingsActive = true;
		} 
		else 
		{
			PlayerOwner.ClearCameraSettingsByInstigator(this, 2.f);
			bCameraSettingsActive = false;
		}
	}

	void UpdateBeamLocation(USceneComponent TargetComponent)
	{
		TimeControlBeamComponent.SetNiagaraVariableVec3("User.BeamStart", SpawnedTimeControlWatch.ActorLocation);
		TimeControlBeamComponent.SetNiagaraVariableVec3("User.BeamEnd", TargetComponent.WorldLocation);
	}

	void ApplyPoi(UTimeControlActorComponent TargetComponent)
	{
		if(bHasPoi == false)
		{
			bHasPoi = true;
			FHazePointOfInterest Poi;
			Poi.InitializeAsInputAssist();
			Poi.InputPauseTime = 2.f;
			Poi.FocusTarget.Component = TargetComponent;	
			Poi.FocusTarget.LocalOffset = TargetComponent.PointOfInterestOffset.Location;
			Poi.Blend = TargetComponent.PointOfInterestBlendTime;	
			PlayerOwner.ApplyPointOfInterest(Poi, this, EHazeCameraPriority::High);
		}
	}

	void ClearPoi()
	{
		bHasPoi = false;
		PlayerOwner.ClearPointOfInterestByInstigator(this);
	}
	
	UFUNCTION()
	void SetUnwitherAndTimeWarpParameters(FVector Location, float Radius, float TimeOffset = 0.0f)
	{
		Material::SetVectorParameterValue(WorldShaderParameters, n"UnwitherSphere", FLinearColor(Location.X, Location.Y, Location.Z, Radius));
		Material::SetScalarParameterValue(WorldShaderParameters, n"BirdTimeOffset", TimeOffset);
		auto CollectionInstance = Niagara::GetNiagaraParameterCollection(WorldNiagaraParameters);
		CollectionInstance.SetVector4Parameter("UnwitherSphere", FVector4(Location.X, Location.Y, Location.Z, Radius));
		CollectionInstance.SetFloatParameter("BirdTimeOffset", TimeOffset);
	}
}

