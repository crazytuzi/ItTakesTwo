import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoilSneakyBush;

import void TriggerExitShapeBeginPlay() from "Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBushExit";

bool CanGroundPoundIntoSneakyBush(AHazePlayerCharacter Player)
{
	if(!Player.IsCody())
		return false;

	auto ManagerComponent = UMoleStealthPlayerComponent::Get(Player);
	if(ManagerComponent.BushIsActive())
		return false;

	if(ManagerComponent.IsInsideGroundPoundableAreaCount == 0)
		return false;
	
	if(!ManagerComponent.bCanGroundpoundIntoBush)
		return false;

	auto PlantComp = UControllablePlantsComponent::Get(Player);
	if(PlantComp.LinkedActivatingSoil == nullptr)
		return false;

	return true;
}


class USneakyBushMovementComponent : UHazeMovementComponent
{
	ASneakyBush PlantOwner;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		Super::BeginPlay();
		PlantOwner = Cast<ASneakyBush>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	float GetWalkableAngle() const
	{
		return 55.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetCeilingAngle() const
	{
		return 30.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetMoveSpeed() const
	{
		return 950.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetRotationSpeed() const
	{
		return 0.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetMaxFallSpeed() const
	{
		return 1800.f;
	}

	UFUNCTION(BlueprintOverride)
	float GetStepAmount(float WantedAmount) const
	{
		return WantedAmount < 0.f ? 40.f : WantedAmount;
	}

	UFUNCTION(BlueprintOverride)
	float GetGravityMultiplier() const
	{
		return -3.f;
	}
}

UCLASS(Abstract)
class ASneakyBush : AControllablePlant
{	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;
	default CollisionComp.CapsuleHalfHeight = 300.f;
	default CollisionComp.CapsuleRadius = 300.f;
	default CollisionComp.SetCollisionProfileName(n"PlayerCharacter");
	default CollisionComp.RelativeLocation = FVector(0.f, 0.f, CollisionComp.CapsuleHalfHeight);

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GroundPoundWidgetLocation;
	default GroundPoundWidgetLocation.RelativeLocation = FVector(0.f, 0.f, 200.f);

	UPROPERTY(EditDefaultsOnly)
	float PaintGroundRadius = 300.f;

	UPROPERTY(EditDefaultsOnly)
	float InsideBushSphereRadius = 600.f;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;

	UPROPERTY()
	FText MoveTutorialText;

	UHazeUserWidget GPWidget;

	UPROPERTY(DefaultComponent)
	USneakyBushMovementComponent MovementComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = false;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;
	

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DeactivateEffect;

	APaintablePlane ActivePaintablePlain;
	bool bIsDisabled = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Cody = Game::GetCody();
		MovementComp.Setup(CollisionComp);

	#if TEST
		Debug::RegisterActorLogger(this, 100);
	#endif
			
		AddCapability(n"SneakyBushMovementCapability");
		BlockCapabilities(CapabilityTags::Movement, this);
		Mesh.SetHiddenInGame(true);
	}


    void UpdateInsideOutsideBush()
    {
		AHazePlayerCharacter Player = Game::GetMay();
		if(Player == nullptr)
			return;

		const float Distance = Player.GetDistanceTo(this);
		if(Distance < InsideBushSphereRadius)
		{
			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
			devEnsure(ManagerComponent != nullptr, "MoleStealthPlayerComponent, the MoleStealthManager must be created");
			ManagerComponent.SetMayInsideBush(true);
			auto PlayerHazeAkComp = UHazeAkComponent::GetOrCreate(Player);
			PlayerHazeAkComp.SetRTPCValue("Rtpc_Character_IsInBush", 1.f);
		}
		else if(Distance > InsideBushSphereRadius + 100)
		{
			auto ManagerComponent = UMoleStealthPlayerComponent::Get(Game::GetCody());
			ManagerComponent.SetMayInsideBush(false);
			auto PlayerHazeAkComp = UHazeAkComponent::GetOrCreate(Player);
			PlayerHazeAkComp.SetRTPCValue("Rtpc_Character_IsInBush", 0.f);
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AHazePlayerCharacter Cody = Game::GetCody();
		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Cody);

		if(ManagerComponent != nullptr)
		{		
			if(ManagerComponent.bCodyIsABush)
				ManagerComponent.bCanGroundpoundIntoBush = false;
			else
				ManagerComponent.bCanGroundpoundIntoBush = GetDistanceTo(Cody) <= InsideBushSphereRadius;

			if(CanGroundPoundIntoSneakyBush(Cody))
			{
				if(GPWidget == nullptr)
				{
					GPWidget = Cody.AddWidget(GroundPoundWidget);
					GPWidget.AttachWidgetToComponent(GroundPoundWidgetLocation);
				}
			}
			else
			{
				if(GPWidget != nullptr)
				{
					Cody.RemoveWidget(GPWidget);
					GPWidget = nullptr;
				}
			}

			if(ActivePaintablePlain != nullptr && ManagerComponent.BushIsActive())
			{
				ActivePaintablePlain.LerpAndDrawTexture(GetActorLocation(), PaintGroundRadius, FLinearColor(1, 0, 0, 0), FLinearColor::White);
			}	

			if(ManagerComponent.bCodyIsABush)
			{
				UpdateInsideOutsideBush();
			}
		}
	}

	bool CanMove() const
	{
		return true;
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		AddPlayerSheet();
	}

	void OnActivatePlant() override
	{
		
		auto Cody = Game::GetCody();
		UnblockCapabilities(CapabilityTags::Movement, this);
		Cody.ApplyCameraSettings(CameraSettings, 2.f, this, EHazeCameraPriority::Maximum);
		SetActorLocation(Cody.GetActorLocation());
		if(bIsDisabled)
		{
			EnableActor(Cody);
			bIsDisabled = false;
		}

		Capability::AddPlayerCapabilityRequest(n"SneakyBushPlayerWantingToHideCapability", EHazeSelectPlayer::May);
		USubmersibleSoilComponent SoilComp = GetActivatingSoilComponentFromPlayer(Cody);
		ASubmersibleSoilSneakyBush Soil = Cast<ASubmersibleSoilSneakyBush>(SoilComp.GetOwner());
		ActivePaintablePlain = Soil.PaintablePlain;

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Cody);
			
		if(GPWidget != nullptr)
		{
			Cody.RemoveWidget(GPWidget);
			GPWidget = nullptr;
		}

		TriggerExitShapeBeginPlay();
	}

	void OnDeactivatePlant() override
	{	
		auto Cody = Game::GetCody();
		BlockCapabilities(CapabilityTags::Movement, this);
		Cody.ClearCameraSettingsByInstigator(this);
		ActivePaintablePlain = nullptr;

		auto ManagerComponent = UMoleStealthPlayerComponent::Get(Cody);
		
		// We need to deactivate mays inside bush data if cody stops beeing a bush
		if(ManagerComponent != nullptr && ManagerComponent.bMayIsInsideCodysBush)
		{
			ManagerComponent.SetMayInsideBush(false);
			AHazePlayerCharacter Player = Game::GetMay();
			if(Player != nullptr)
			{
				auto PlayerHazeAkComp = UHazeAkComponent::Get(Player);
				if(PlayerHazeAkComp != nullptr)
					PlayerHazeAkComp.SetRTPCValue("Rtpc_Character_IsInBush", 0.f);
			}
		}
	
		bIsDisabled = true;
		DisableActor(Cody);
	
		if(DeactivateEffect != nullptr)
			Niagara::SpawnSystemAtLocation(DeactivateEffect, GetActorCenterLocation());

		Capability::RemovePlayerCapabilityRequest(n"SneakyBushPlayerWantingToHideCapability", EHazeSelectPlayer::May);
		OnUnpossessPlant(ActorLocation, ActorRotation, EControllablePlantExitBehavior::PlantLocationGround);
	}
}
