import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionLaunchComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionSettings;

import USubmersibleSoilComponent GetActivatingSoilComponentFromPlayer(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent";

settings DandelionSettingsDefault for UDandelionSettings 
{

}

class ADandelionVFXActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UNiagaraComponent Niagara;

	private float Elapsed = 0.0f;

	void ActivateVFX()
	{
		Niagara.Activate();
		SetActorTickEnabled(false);
	}

	void DeactivateVFX()
	{
		SetActorTickEnabled(true);
		Elapsed = 5.0f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Elapsed -= DeltaTime;

		if(Elapsed < 0.0f)
		{
			Niagara.Deactivate();
			SetActorTickEnabled(false);
		}
	}
}

UCLASS(Abstract)
class ADandelion : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleComponent;

	UPROPERTY(DefaultComponent, Attach = CapsuleComponent)
	UHazeCharacterSkeletalMeshComponent DandelionMesh;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UHazeCameraComponent Camera;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UPROPERTY(Category = Settings)
	protected UDandelionSettings DefaultDandelionSettings = DandelionSettingsDefault;
	UDandelionSettings DandelionSettings;

	UPROPERTY(Category = Audio)
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect EnterFeedbackEffect;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect ExitFeedbackEffect;

	UPROPERTY()
	UNiagaraSystem TrailVFX;

	float PendingLaunchHeight = 0.0f;
	float PendingLaunchTime = 1.0f;

	FVector WantedDirection;
	FVector HorizontalVelocity;
	float VerticalDelta = 0.0f;

	bool bDandelionActive = false;
	bool bKilledBySomething = false;
	bool bWantsToExitDandelion = false;
	bool bActivateLaunchCamera = false;

	ADandelionVFXActor VFXActor = nullptr;

	default bShowplayerFromPlant = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplySettings(DefaultDandelionSettings, this, EHazeSettingsPriority::Gameplay);
		DandelionSettings = UDandelionSettings::GetSettings(this);

		MovementComponent.Setup(CapsuleComponent);
		AddCapability(n"DandelionActivateCapability");
		AddCapability(n"DandelionPhysicsCapability");
		AddCapability(AudioCapabilityClass);

		Camera = UHazeCameraComponent::Get(OwnerPlayer);

		VFXActor = ADandelionVFXActor::Spawn();
		VFXActor.Niagara.SetAsset(TrailVFX);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason) override
	{
		if(VFXActor != nullptr)
		{
			VFXActor.DestroyActor();
			VFXActor = nullptr;
		}
	}

	void ActivateTrailVFX()
	{
		VFXActor.AttachToComponent(DandelionMesh, n"Head");
		FHitResult Hit;
		VFXActor.SetActorRelativeLocation(FVector(0.0f, 0.0f, 120.0f), false, Hit, true);
		VFXActor.ActivateVFX();
	}

	void DeactivateVFXTrail()
	{
		VFXActor.DeactivateVFX();
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		ActivateTrailVFX();
		AddPlayerSheet();
	}

	void OnActivatePlant() override
	{
		bActivateLaunchCamera = true;
		bWantsToExitDandelion = false;
		bKilledBySomething = false;
		bDandelionActive = true;
		WantedDirection = FVector::ZeroVector;
		HorizontalVelocity = FVector::ZeroVector;
		
		MovementComponent.StopMovement();
		UDandelionComponent DandelionComp = UDandelionComponent::GetOrCreate(OwnerPlayer);
		USubmersibleSoilComponent SoilComp = GetActivatingSoilComponentFromPlayer(OwnerPlayer);
		DandelionComp.bDandelionActive = true;

		if(SoilComp != nullptr)
		{
			UDandelionLaunchComponent DandelionLaunchComp = UDandelionLaunchComponent::Get(SoilComp.Owner);

			if(DandelionLaunchComp != nullptr)
			{
				LaunchDandelion(DandelionLaunchComp.LaunchHeight, DandelionLaunchComp.LaunchTime);
			}
		}

		SetActorHiddenInGame(false);

		if(EnterFeedbackEffect != nullptr)
			OwnerPlayer.PlayForceFeedback(EnterFeedbackEffect, false, false, n"EnterDandelion");

		StopEnterSoilAnimationOnPlayer();
	}

	void TriggerCameraTransitionToPlant()
	{
		if(SpringArmSettings != nullptr)
			OwnerPlayer.ApplyCameraSettings(SpringArmSettings, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Medium);
	}

	void TriggerCameraTransitionToPlayer()
	{
		OwnerPlayer.ClearCameraSettingsByInstigator(this);
	}

	// Extract cody from soil and remove dandelion
	void KillDandelion()
	{
		bKilledBySomething = true;
		bDandelionActive = false;
	}

	void PreDeactivate() override
	{
		DeactivateVFXTrail();
	}

	void OnDeactivatePlant()
	{
		TriggerCameraTransitionToPlayer();
		SetActorHiddenInGame(true);
		OnUnpossessPlant(ActorLocation, HorizontalVelocity.GetSafeNormal().Rotation(), EControllablePlantExitBehavior::PlantLocation);
		if(ExitFeedbackEffect != nullptr)
			OwnerPlayer.PlayForceFeedback(ExitFeedbackEffect, false, false, n"ExitDandelion");
	}

	void UpdateInput(const FVector& InWantedDirection, bool bInExitDandelion)
	{
		WantedDirection = InWantedDirection;
	}

	void LaunchDandelion(float InLaunchHeight, float InLaunchTime)
	{
		PendingLaunchHeight = InLaunchHeight;
		PendingLaunchTime = InLaunchTime;
	}
}
