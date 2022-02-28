import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagnetNiagaraComponent;
import Vino.Camera.Components.CameraSpringArmComponent;

event void FOnBasePadSwitchedPolarity();
event void FOnBasePadActivatedAndUnhidden();
event void FOnBasePadDeactivatedAndHidden();
event void FOnBasePadPlayerAttached();
event void FOnBasePadPlayerDetached();
event void FOnBasePadPlayerBoosted();

UCLASS(Abstract, HideCategories = "Rendering Debug Replication Input Actor LOD Cooking")
class AMagnetBasePad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = Platform)
	UStaticMeshComponent MagnetForceSphere;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCameraSpringArmComponent SpringArmComponent;
	default SpringArmComponent.SetRelativeLocation(FVector(400.f, 0.f, 0.f));
	default SpringArmComponent.OverrideSettings.bUsePivotOffset = true;
	default SpringArmComponent.OverrideSettings.bUseCameraOffset = true;
	default SpringArmComponent.OverrideSettings.bUseCameraOffsetOwnerSpace = true;
	default SpringArmComponent.OverrideSettings.PivotOffset = FVector::ZeroVector;
	default SpringArmComponent.OverrideSettings.CameraOffset = FVector::ZeroVector;
	default SpringArmComponent.OverrideSettings.CameraOffsetOwnerSpace = FVector::ZeroVector;

	UPROPERTY(DefaultComponent, Attach = SpringArmComponent)
	UHazeCameraComponent CameraComponent;


	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface RedMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ForceRedMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ForceBlueMaterial;


	UPROPERTY()
	EMagnetPolarity Polarity;


	UPROPERTY(Category = "Attraction")
	float AttractionActivationDistance = 2000.f;

	UPROPERTY(Category = "Attraction")
	float LaunchSpeed = 8000.f;

	UPROPERTY(Category = "Attraction", meta = (ClampMin = "0.5", ClampMax = "1.0", UIMin = "0.5", UIMax = "1.0"))
	float JumpFromPerchDurationMultiplier = 1.f;

	UPROPERTY(Category = "Attraction")
	float JumpFromPerchGravityMultiplier = 1.f;

	UPROPERTY(Category = "Attraction")
	bool bUseLongJumpFromMagnetPerch = true;

	UPROPERTY(Category = "Attraction")
	float PerchCameraDistanceMultiplier = 1.f;


	UPROPERTY(Category = "Boost")
	float BoostActivationDistance = 400.f;

	UPROPERTY(Category = "Boost")
	float BoostForce = 4000.f;

	UPROPERTY(Category = "Boost")
	float BoostForceWithPackage = 4000.f;


	private bool bShotByCannon = false;


	UPROPERTY(DefaultComponent, Attach = Platform)
	UMagneticPerchAndBoostComponent MagneticCompCody;
	default MagneticCompCody.SetRelativeLocation(FVector(80.f, 0.f, 0.f), false, FHitResult(), true);
	default MagneticCompCody.bUseGenericMagnetAnimation = false;

	UPROPERTY(DefaultComponent, Attach = Platform)
	UMagneticPerchAndBoostComponent MagneticCompMay;
	default MagneticCompMay.SetRelativeLocation(FVector(80.f, 0.f, 0.f), false, FHitResult(), true);
	default MagneticCompMay.bUseGenericMagnetAnimation = false;

	UPROPERTY(DefaultComponent, Attach = Platform)
	private USceneComponent EffectsRoot;

	UPROPERTY(DefaultComponent, Attach = EffectsRoot)
	private UMagnetNiagaraComponent BoostEffect;
	default BoostEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = EffectsRoot)
	private UMagnetNiagaraComponent PerchEffect;
	default PerchEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = EffectsRoot)
	private UMagnetNiagaraComponent JumpFromPerchEffect;
	default JumpFromPerchEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = EffectsRoot)
	private UMagnetNiagaraComponent PerchAffordability;
	default PerchAffordability.SetAutoActivate(true);

	UPROPERTY(DefaultComponent, Attach = EffectsRoot)
	private UMagnetNiagaraComponent BoostAffordability;
	default BoostAffordability.SetAutoActivate(true);


	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;


	UPROPERTY()
	FOnBasePadSwitchedPolarity OnBasePadSwitchedPolarity;

	UPROPERTY()
	FOnBasePadActivatedAndUnhidden OnBasePadActivatedAndUnhidden;

	UPROPERTY()
	FOnBasePadDeactivatedAndHidden OnBasePadDeactivatedAndHidden;

	UPROPERTY()
	FOnBasePadPlayerAttached OnBasePadPlayerAttached;

	UPROPERTY()
	FOnBasePadPlayerDetached OnBasePadPlayerDetached;

	UPROPERTY()
	FOnBasePadPlayerBoosted OnBasePadPlayerBoosted;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MagneticCompCody.Polarity = Polarity;
		MagneticCompMay.Polarity = Polarity;

		MagneticCompCody.ValidationType = EHazeActivationPointActivatorType::Cody;
		MagneticCompMay.ValidationType = EHazeActivationPointActivatorType::May;

		InitializeActivationDistances();

		MagneticCompCody.LaunchSpeed = LaunchSpeed;
		MagneticCompCody.BoostLaunchForce = BoostForce;
		MagneticCompCody.CarryingPickupBoostForce = BoostForceWithPackage;

		MagneticCompMay.LaunchSpeed = LaunchSpeed;
		MagneticCompMay.BoostLaunchForce = BoostForce;
		MagneticCompMay.CarryingPickupBoostForce = BoostForceWithPackage;

		BoostEffect.InitializePolarity(Polarity);
		PerchEffect.InitializePolarity(Polarity);
		JumpFromPerchEffect.InitializePolarity(Polarity);

		BoostAffordability.InitializePolarity(Polarity);
		PerchAffordability.InitializePolarity(Polarity);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Polarity == EMagnetPolarity::Plus_Red)
		{
			BoostAffordability.SetRenderedForPlayer(Game::GetMay(), false);
			PerchAffordability.SetRenderedForPlayer(Game::GetCody(), false);
		}
		else
		{
			BoostAffordability.SetRenderedForPlayer(Game::GetCody(), false);
			PerchAffordability.SetRenderedForPlayer(Game::GetMay(), false);
		}
	}

	private void InitializeActivationDistances()
	{
		float ActivationDistanceCody;
		float ActivationDistanceMay;

		if(Polarity == EMagnetPolarity::Plus_Red)
		{
			ActivationDistanceCody = BoostActivationDistance;
			ActivationDistanceMay = AttractionActivationDistance;
		}
		else
		{
			ActivationDistanceCody = AttractionActivationDistance;
			ActivationDistanceMay = BoostActivationDistance;
		}

		MagneticCompCody.InitializeDistance(EHazeActivationPointDistanceType::Visible, FMath::Clamp(ActivationDistanceCody * 4.f, 4000, BIG_NUMBER));
		MagneticCompCody.InitializeDistance(EHazeActivationPointDistanceType::Targetable, FMath::Clamp(ActivationDistanceCody * 2.f, 2000, BIG_NUMBER));
		MagneticCompCody.InitializeDistance(EHazeActivationPointDistanceType::Selectable, ActivationDistanceCody);

		MagneticCompMay.InitializeDistance(EHazeActivationPointDistanceType::Visible, FMath::Clamp(ActivationDistanceMay * 4.f, 4000, BIG_NUMBER));
		MagneticCompMay.InitializeDistance(EHazeActivationPointDistanceType::Targetable, FMath::Clamp(ActivationDistanceMay * 2.f, 2000, BIG_NUMBER));
		MagneticCompMay.InitializeDistance(EHazeActivationPointDistanceType::Selectable, ActivationDistanceMay);
	}

	UFUNCTION(BlueprintCallable)
	void StartEventListeners()
	{
		MagneticCompCody.OnBasePadUsedPerchStateChanged.AddUFunction(this, n"UsingStateChanged");
		MagneticCompMay.OnBasePadUsedPerchStateChanged.AddUFunction(this, n"UsingStateChanged");
		MagneticCompCody.OnBasePadBoost.AddUFunction(this, n"Boosting");
		MagneticCompMay.OnBasePadBoost.AddUFunction(this, n"Boosting");
	}

	UFUNCTION()
	void UsingStateChanged(bool bBeingUsed)
	{
		if(bBeingUsed)
		{ 
			OnBasePadPlayerAttached.Broadcast();
		}
		else
		{
			OnBasePadPlayerDetached.Broadcast();
		}
	}

	UFUNCTION()
	void Boosting()
	{
		OnBasePadPlayerBoosted.Broadcast();
	}

	UFUNCTION()
	void OverridePolarity(EMagnetPolarity NewPolarity)
	{
		if(NewPolarity != Polarity)
		{
			Polarity = NewPolarity;

			MagneticCompCody.Polarity = Polarity;
			MagneticCompMay.Polarity = Polarity;
			OnBasePadSwitchedPolarity.Broadcast();
		}
	}

	UFUNCTION()
	void ActivateAndUnhideBasePad()
	{
		SetActorHiddenInGame(false);

		Platform.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		OnBasePadActivatedAndUnhidden.Broadcast();
		MagneticCompMay.bIsDisabled = false;
		MagneticCompCody.bIsDisabled = false;

		MagneticCompCody.bPadIsActive = true;
		MagneticCompMay.bPadIsActive = true;
	}

	void DeactivateAndHideBasePad()
	{
		MagneticCompCody.bPadIsActive = false;
		MagneticCompMay.bPadIsActive = false;

		if(Game::GetCody() != nullptr)
		{
			if(Game::GetCody().RootComponent.IsAttachedTo(this))
				Game::GetCody().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}
		if(Game::GetMay() != nullptr)
		{
			if(Game::GetMay().RootComponent.IsAttachedTo(this))
				Game::GetMay().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		SetActorHiddenInGame(true);

		Platform.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		OnBasePadDeactivatedAndHidden.Broadcast();
		MagneticCompMay.bIsDisabled = true;
		MagneticCompCody.bIsDisabled = true;
	}

	void PlayBoostEffect()
	{
		BoostEffect.Play();
	}

	void PlayPerchEffect()
	{
		PerchEffect.Play();
	}

	void StopPerchEffect()
	{
		PerchEffect.Stop();
	}

	void PlayJumpFromPerchEffect()
	{
		JumpFromPerchEffect.Play();
	}

	void SetShotByCannon(bool bValue)
	{
		bShotByCannon = bValue;
		MagneticCompMay.bShotByCannon = bValue;
		MagneticCompCody.bShotByCannon = bValue;
	}

	UFUNCTION(BlueprintPure)
	bool GetShotByCannon()
	{
		return bShotByCannon;
	}
}