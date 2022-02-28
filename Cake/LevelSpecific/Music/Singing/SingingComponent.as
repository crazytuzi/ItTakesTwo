import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongFeature;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSong;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLife;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongProjectile;
import Vino.Interactions.Widgets.InteractionContextualWidget;
import Cake.LevelSpecific.Music.Singing.InstrumentActivation.InstrumentActivationComponent;
import Cake.LevelSpecific.Music.Singing.SingingSettings;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.Singing.SingingWidget;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

settings SingingSettingsDefault for USingingSettings
{
	SingingSettingsDefault.SongOfLifeDurationMaximum = 5.0f;
}

enum ESongOfLifeState
{
	Singing,
	Cooldown,
	Recharge,
	Depleted,
	None
}

UCLASS(NotBlueprintable)
class ASongOfLifeVFX : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UNiagaraComponent NiagaraComp;
	default NiagaraComp.bAutoActivate = false;
	default NiagaraComp.bAbsoluteLocation = true;

	private float Elapsed = 0.0f;
	private bool bVFXActive = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Elapsed -= DeltaSeconds;

		if(Elapsed < 0.0f)
		{
			SetActorTickEnabled(false);
			NiagaraComp.Deactivate();
			SetActorTickEnabled(false);
		}
	}

	void ActivateVFX(float SizeMulti)
	{
		if(bVFXActive)
			return;

		NiagaraComp.Activate();
		NiagaraComp.SetNiagaraVariableFloat("SizeMulti", SizeMulti);
		bVFXActive = true;
		SetActorTickEnabled(false);
	}

	void DeactivateVFX()
	{
		if(!bVFXActive)
			return;

		Elapsed = 2.0f;
		bVFXActive = false;
		SetActorTickEnabled(true);
	}
}

void ReturnPowerfulSongProjectile(AHazeActor Owner, APowerfulSongProjectile Projectile)
{
	USingingComponent SingingComp = USingingComponent::Get(Owner);

	if(SingingComp != nullptr)
	{
		SingingComp.ReturnProjectile(Projectile);
	}
}

bool IsPlayerAimingWithPowerfulSong(AHazePlayerCharacter Player)
{
	USingingComponent SingingComp = USingingComponent::Get(Player);

	if(SingingComp != nullptr)
	{
		return SingingComp.bIsAiming;
	}

	return false;
}

bool IsPowerfulSongOnCooldown(AActor Owner)
{
	USingingComponent SingingComp = USingingComponent::Get(Owner);

	if(SingingComp != nullptr)
	{
		return SingingComp.PowerfulSongCooldown > 0.0f;
	}

	return false;
}

UCLASS(Abstract)
class USingingComponent : UActorComponent
{
	UPROPERTY(Category = "PowerfulSong")
	ULocomotionFeaturePowerfulSong PowerfulSongFeature;
	
	UPROPERTY(Category = "PowerfulSong")
	UHazeLocomotionStateMachineAsset PowerfulSongNotAimingLocomotion;

	UPROPERTY(Category = "PowerfulSong")
	UHazeLocomotionStateMachineAsset PowerfulSongAimingLocomotion;

	UPROPERTY(Category = "PowerfulSong")
	UCurveFloat PowerfulSongFieldOfViewCurve;

	UPROPERTY(Category = "PowerfulSong")
	UForceFeedbackEffect PowerfulSongForceFeedback;

	UPROPERTY(Category = Camera)
	TSubclassOf<UCameraShakeBase> ShootingCameraShake;

	UPROPERTY(Category = Camera)
	TSubclassOf<UCameraShakeBase> ChargingCameraShake;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset PowerfulSongAimCamSettings;

	UPROPERTY(EditDefaultsOnly, Category = Camera)
	protected UHazeCameraSpringArmSettingsDataAsset AltPowerfulSongAimCamSettings;

	private UHazeCameraSpringArmSettingsDataAsset CurrentAimCameraSettings;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset SongOfLifeCamSettings;

	UPROPERTY(Category = Animation)
	UAnimSequence SongOfLifeAnim;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	UNiagaraSystem SongOfLifeEffect;

	// Size of the effect. This value - InputRadiusModifier when the trigger button is pressed to the max.
	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float EffectRadiusDefault = 500.0f;

	// How much the radius will decrease if the trigger is not held down fully.
	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float InputRadiusModifier = 200.0f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float SpringStiffness = 40.0f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float SpringDamping = 0.25f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float VortexVelocityAppearAccelerationTime = 4.0f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float VortexVelocityDisappearAccelerationTime = 0.5f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float VortexVelocity = 250.0f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	float VortexVelocityModifier = 4500.0f;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	UNiagaraSystem SongOfLifeVFX;

	UPROPERTY(EditDefaultsOnly, Category = "SongOfLife|Effect")
	UNiagaraSystem SongOfLifeMeshSamplerVFX;

	// This will prevent the user from spamming in and out of aiming.
	UPROPERTY()
	float PowerfulSongAimCooldown = 0.35f;

	UPROPERTY(Category = Flying)
	USingingSettings FlyingSingingSettings = Asset("/Game/Blueprints/LevelSpecific/Music/Singing/DA_SingingSettings_Flying.DA_SingingSettings_Flying");

	UPROPERTY(Category = SingingSettings)
	USingingSettings SingingSettings = SingingSettingsDefault;

	USingingSettings DefaultSingingSettings;

	private UNiagaraComponent SongOfLifeEffectComponent = nullptr;

	UPROPERTY(Category = PowerfulSong)
	TSubclassOf<APowerfulSongProjectile> ProjectileClass = Asset("/Game/Blueprints/LevelSpecific/Music/Singing/PowerfulSong/BP_PowerfulSongProjectile.BP_PowerfulSongProjectile_C");

	UPROPERTY(Category = Widget)
	TSubclassOf<USingingWidget> SingingWidgetClass;

	USingingWidget SingingWidgetInstance;

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "Update Song Of Life Widget"))
	void BP_UpdateSongOfLifeWidget(float Progress, UHazeUserWidget SongOfLifeWidget){}

	AHazePlayerCharacter Player;

	bool bInstrumentActive = false;
	bool bChargingPowerfulSong = false;
	bool bShoutWithoutAim = false;
	bool bIsShooting = false;

	TArray<APowerfulSongProjectile> AllProjectiles;	// easy access for destruction and debug.
	TArray<APowerfulSongProjectile> CachedPowerfulSongProjectiles;
	TArray<APowerfulSongProjectile> ActivePowerfulSongProjectiles;

	int NetworkInstanceCount = 0;

	int32 SingingActiveVFXCount = 0;

	// Determines the speed which the character rotates towards the aiming location.
	UPROPERTY(Category = Movement)
	float AimLerpSpeed = 10.0f;

	float SongOfLifeCurrent = 0.0f;
	float SongOfLifeRechargeCooldownCurrent = 0.0f;
	float SongofLifeCooldownCurrent = 0.0f;
	ESongOfLifeState SongOfLifeState = ESongOfLifeState::None;

	float PowerfulSongCooldown = 0;
	float ShuffleRotation = 0.0f;

	bool bInfiniteSongOfLife = false;
	bool bIsAiming = false;

	UFUNCTION(BlueprintPure)
	float GetSongOfLifeValue() const { return SongOfLifeCurrent; }

	UFUNCTION(BlueprintPure)
	float GetSongOfLifeDurationMaximum() const { return SingingSettings != nullptr ? SingingSettings.SongOfLifeDurationMaximum : 0.0f; }

	UFUNCTION(BlueprintPure)
	ESongOfLifeState GetSongOflifeCurrentState() const { return SongOfLifeState; }

	float GetSongOfLifeChargeAsFraction() const property
	{
		if(SingingSettings == nullptr)
			return 0.0f;

		return Math::Saturate(SongOfLifeCurrent / SingingSettings.SongOfLifeDurationMaximum);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentAimCameraSettings = PowerfulSongAimCamSettings;
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplySettings(SingingSettings, this, EHazeSettingsPriority::Gameplay);
		DefaultSingingSettings = USingingSettings::GetSettings(Player);

		if(SingingWidgetClass.IsValid())
		{
			SingingWidgetInstance = Cast<USingingWidget>(Player.AddWidgetToHUDSlot(n"LevelAbility", SingingWidgetClass));
		}
	}

	void ApplyAimCameraSettings()
	{
		if(CurrentAimCameraSettings != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 0.5f;
			Player.ApplyCameraSettings(CurrentAimCameraSettings, Blend, this, EHazeCameraPriority::High);
		}
	}

	void ClearCameraAimSettings()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	void DestroyAllProjectiles()
	{
		for(APowerfulSongProjectile Projectile : AllProjectiles)
			Projectile.DestroyActor();

		AllProjectiles.Empty();
		CachedPowerfulSongProjectiles.Empty();
		ActivePowerfulSongProjectiles.Empty();
	}

	APowerfulSongProjectile GetAvailableProjectileInstance() property
	{
		const int NumEntries = CachedPowerfulSongProjectiles.Num();

		if(NumEntries == 0 && 
		devEnsure(ActivePowerfulSongProjectiles.Num() != 0))	// Just pick one from the "active" list
		{
			ReturnProjectile(ActivePowerfulSongProjectiles[0]);
		}

		APowerfulSongProjectile Projectile = CachedPowerfulSongProjectiles.Last();
		devEnsure(Projectile != nullptr);
		CachedPowerfulSongProjectiles.RemoveAt(NumEntries - 1);
		ActivePowerfulSongProjectiles.Add(Projectile);
		return Projectile;
	}

	void ReturnProjectile(APowerfulSongProjectile Projectile)
	{
		if(Projectile == nullptr || CachedPowerfulSongProjectiles.Contains(Projectile))
			return;

		if(ActivePowerfulSongProjectiles.Contains(Projectile))
			ActivePowerfulSongProjectiles.Remove(Projectile);

		CachedPowerfulSongProjectiles.Add(Projectile);
		Projectile.DisableActor(this);
	}

	void InstantiateProjectile()
	{
		APowerfulSongProjectile NewProjectile = Cast<APowerfulSongProjectile>(SpawnPersistentActor(ProjectileClass, 
			Owner.ActorLocation, FRotator::ZeroRotator, bDeferredSpawn = true));

		NewProjectile.MakeNetworked(this, NetworkInstanceCount);
		NewProjectile.SetControlSide(Owner);
		NewProjectile.OwnerPlayer = Player;
		FinishSpawningActor(NewProjectile);
	
		//NewProjectile.SetActorHiddenInGame(true);
		NewProjectile.InitCapabilities();
		NewProjectile.DisableActor(this);
		NetworkInstanceCount++;
		CachedPowerfulSongProjectiles.Add(NewProjectile);
		AllProjectiles.Add(NewProjectile);
	}

	void ApplyFlyingSettings(UObject Instigator)
	{
		Player.ApplySettings(FlyingSingingSettings, Instigator, EHazeSettingsPriority::Override);
	}

	void ClearFlyingSettings(UObject Instigator)
	{
		Player.ClearSettingsWithAsset(FlyingSingingSettings, Instigator);
	}

	void ApplyHoverSettings(UObject Instigator)
	{
		
	}

	void ClearHoverSettings(UObject Instigator)
	{
		
	}

	void ActivatePowerfulSong()
	{
		if(SingingWidgetInstance != nullptr)
		{
			SingingWidgetInstance.BP_OnPowerfulSong();
		}
	}

	void DeactivatePowerfulSong()
	{
	}

	void ActivateSongOfLife()
	{		
		ActivateParticleEffect();
		Player.ApplyCameraSettings(SongOfLifeCamSettings, FHazeCameraBlendSettings(2.0f), this, EHazeCameraPriority::High);

		if(SingingWidgetInstance != nullptr)
			SingingWidgetInstance.BP_OnSongOfLifeBegin();
	}		

	void DeactivateSongOfLife()
	{
		Player.ClearCameraSettingsByInstigator(this);

		if(SingingWidgetInstance != nullptr)
			SingingWidgetInstance.BP_OnSongOfLifeEnd();
	}

	void ActivateParticleEffect()
	{
		EffectComponent.Activate();
	}

	void SetEffectRadius(float InEffectRadius)
	{
		EffectComponent.SetNiagaraVariableFloat("User.Radius", InEffectRadius);
	}

	void SetEffectVortexVel(float InVortexVel)
	{
		EffectComponent.SetNiagaraVariableFloat("User.VortexVel", InVortexVel);
	}

	UNiagaraComponent GetEffectComponent() property
	{
		if(SongOfLifeEffectComponent == nullptr)
		{
			SongOfLifeEffectComponent = Niagara::SpawnSystemAttached(SongOfLifeEffect, Owner.RootComponent, NAME_None, FVector(0.0f, 0.0f, 200.0f), FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			SongOfLifeEffectComponent.bAbsoluteRotation = true;
			SongOfLifeEffectComponent.Deactivate();
		}
		
		return SongOfLifeEffectComponent;
	}

	void DeactivateParticleEffect()
	{
		EffectComponent.Deactivate();
	}

	void SetParticleEffectVisibility(bool bVisible)
	{
		EffectComponent.SetVisibility(bVisible);
	}

	void UpdateWidgetProgress(float InProgress)
	{
		if(SingingWidgetInstance != nullptr)
		{
			SingingWidgetInstance.BP_UpdateProgress(InProgress);
		}
	}

	void OnSongOfLifeDepleted()
	{
		if(SingingWidgetInstance != nullptr)
		{
			SingingWidgetInstance.BP_OnSongOfLifeDepleted();
		}
	}

	void OnSongOfLifeRechargeStart()
	{
		if(SingingWidgetInstance != nullptr)
		{
			SingingWidgetInstance.BP_OnSongOfLifeRechargeStart();
		}
	}

	void DebugDrawAllHit(float Duration = 0.0f) const
	{
		for(APowerfulSongProjectile Projectile : AllProjectiles)
			Projectile.DrawDebugHits(Duration);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Song Of Life Appear"))
	void BP_OnSongOfLifeAppear(USongOfLifeComponent SongOfLife, UNiagaraComponent Niagara) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Song Of Life Disappear"))
	void BP_OnSongOfLifeDisappear(USongOfLifeComponent SongOfLife, UNiagaraComponent Niagara) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Song Of Life Update"))
	void BP_OnSongOfLifeUpdate(float DeltaTime, USongOfLifeComponent SongOfLife, UNiagaraComponent Niagara) {}

	void OnSongOfLifeAppear(USongOfLifeComponent SongComp)
	{
		ASongOfLifeVFX VFXActor = AddOrGetVFX(SongComp);
		VFXActor.ActivateVFX(SongComp.VFXSizeMulti);
		BP_OnSongOfLifeAppear(SongComp, VFXActor.NiagaraComp);

		if(SingingActiveVFXCount == 0)
			Player.SetCapabilityActionState(n"AudioSongInteractionEffectActive", EHazeActionState::ActiveForOneFrame);

		SingingActiveVFXCount ++;
	}

	void OnSongOfLifeDisappear(USongOfLifeComponent SongComp)
	{
		ASongOfLifeVFX VFXActor = AddOrGetVFX(SongComp);
		BP_OnSongOfLifeDisappear(SongComp, VFXActor.NiagaraComp);
		RemoveVFX(SongComp);
		VFXActor.DeactivateVFX();

		SingingActiveVFXCount --;
		if(SingingActiveVFXCount == 0)
			Player.SetCapabilityActionState(n"AudioSongInteractionEffectInactive", EHazeActionState::ActiveForOneFrame);			
	}

	private TArray<ASongOfLifeVFX> CachedNiagara;
	private TArray<ASongOfLifeVFX> AllVFX;
	private TMap<USongOfLifeComponent, ASongOfLifeVFX> VFXCollection;

	ASongOfLifeVFX AddOrGetVFX(USongOfLifeComponent SongOfLifeComp)
	{
		ASongOfLifeVFX VFXActor = nullptr;
		if(VFXCollection.Find(SongOfLifeComp, VFXActor))
		{
			return VFXActor;
		}

		VFXActor = SpawnNiagaraSystem(SongOfLifeComp);
		VFXCollection.Add(SongOfLifeComp, VFXActor);
		return VFXActor;
	}

	void RemoveVFX(USongOfLifeComponent SongOfLifeComp)
	{
		ASongOfLifeVFX NiagaraComp = nullptr;

		if(VFXCollection.Find(SongOfLifeComp, NiagaraComp))
		{
			CachedNiagara.AddUnique(NiagaraComp);
			VFXCollection.Remove(SongOfLifeComp);
		}
	}

	private ASongOfLifeVFX SpawnNiagaraSystem(USongOfLifeComponent SongOfLifeComp)
	{
		ASongOfLifeVFX VFXActor = nullptr;

		if(CachedNiagara.Num() > 0)
		{
			for(int Index = 0, Num = CachedNiagara.Num(); Index < Num; ++Index)
			{
				// If actor is no longer ticking we have approved that the vfx probably isnt running anymore.
				if(!CachedNiagara[Index].IsActorTickEnabled())
				{
					VFXActor = CachedNiagara[Index];
					CachedNiagara.RemoveAt(Index);
					break;
				}

			}
		}
		
		if(VFXActor == nullptr)
		{
			VFXActor = ASongOfLifeVFX::Spawn();
			AllVFX.Add(VFXActor);
		}

		VFXActor.NiagaraComp.SetAsset(SongOfLifeVFX);
		VFXActor.DeactivateVFX();

		return VFXActor;
	}

	void ClearVFXCollection()
	{
		for(auto VFXActor : AllVFX)
		{
			VFXActor.DestroyActor();
		}

		AllVFX.Empty();
		VFXCollection.Empty();
		CachedNiagara.Empty();
	}

	void SwapCameraAimSettings()
	{
		ClearCameraAimSettings();
		if(CurrentAimCameraSettings == PowerfulSongAimCamSettings)
			CurrentAimCameraSettings = AltPowerfulSongAimCamSettings;
		else
			CurrentAimCameraSettings = PowerfulSongAimCamSettings;
		ApplyAimCameraSettings();
	}
}
