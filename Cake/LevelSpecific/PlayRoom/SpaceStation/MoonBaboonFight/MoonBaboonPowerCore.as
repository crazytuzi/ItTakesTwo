import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.PressurePlate.PressurePlate;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ShutterDoor;
import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)

event void FOnPowerCoreDestroyed();

class AMoonBaboonPowerCore : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UStaticMeshComponent PillarMesh;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UCapsuleComponent PowerCoreCollision;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UStaticMeshComponent ShieldMesh;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UStaticMeshComponent GlassMesh;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UStaticMeshComponent BrokenGlassMesh;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	FHazeTimeLike ExposeTimeLike;
	default ExposeTimeLike.Duration = 1.f;

	UPROPERTY()
	FHazeTimeLike OpenShieldTimeLike;
	default OpenShieldTimeLike.Duration = 1.f;

	FVector StartLocation = FVector::ZeroVector;

	UPROPERTY()
	FVector EndLocation = FVector(0.f, 0.f, 500.f);

	UPROPERTY(NotVisible)
	bool bDestroyed = false;

	bool bGoingUp = false;
	bool bBottomReached = true;
	bool bTopReached = false;
	bool bCoreFullyExposed = false;

	UPROPERTY()
	FOnPowerCoreDestroyed OnPowerCoreDestroyed;

	UPROPERTY()
	bool bPreviewEndOffset = false;
	bool bSaveStartLoc = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroyedEffect;

	UPROPERTY()
	APressurePlate AttachedPressurePlate;
	
	UPROPERTY(Category = "Shutter Doors")
	AShutterDoor TargetShutterDoor;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ElevatorUpEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ElevatorDownEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PowerCoreHitEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ElevatorStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ElevatorStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ShieldOpenEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ShieldCloseEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExposeTimeLike.BindUpdate(this, n"UpdateExpose");
		ExposeTimeLike.BindFinished(this, n"FinishExpose");

		OpenShieldTimeLike.BindUpdate(this, n"UpdateOpenShield");
		OpenShieldTimeLike.BindFinished(this, n"FinishOpenShield");

		AttachedPressurePlate.OnPressurePlateActivated.AddUFunction(this, n"ExposePowerCore");
		AttachedPressurePlate.OnPressurePlateDeactivated.AddUFunction(this, n"HidePowerCore");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerOnPressurePlate");
		BindOnDownImpactedByPlayer(AttachedPressurePlate, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftPressurePlate");
		BindOnDownImpactEndedByPlayer(AttachedPressurePlate, NoImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndOffset)
			BaseComp.SetRelativeLocation(EndLocation);
		else
			BaseComp.SetRelativeLocation(FVector::ZeroVector);

		if (AttachedPressurePlate != nullptr)
			AttachedPressurePlate.AttachToComponent(BaseComp, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerOnPressurePlate(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, -300.f), CameraBlend::Additive(0.8f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLeftPressurePlate(AHazePlayerCharacter Player)
	{
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
	}

	UFUNCTION()
	void ExposePowerCore()
	{
		if (bDestroyed)
			return;
		
		bGoingUp = true;
	 	ExposeTimeLike.Play();

		HazeAkComponent.HazePostEvent(ElevatorUpEvent);

		if (bBottomReached)
		{
			bBottomReached = false;
			HazeAkComponent.HazePostEvent(ElevatorStartEvent);
		}
	}

	UFUNCTION()
	void HidePowerCore()
	{
		bCoreFullyExposed = false;
		bGoingUp = false;
		ExposeTimeLike.Reverse();
		
		HazeAkComponent.HazePostEvent(ElevatorDownEvent);

		if (bTopReached)
		{
			OpenShieldTimeLike.Reverse();
			HazeAkComponent.HazePostEvent(ElevatorStartEvent);
			HazeAkComponent.HazePostEvent(ShieldCloseEvent);
			bTopReached = false;
		}
	}

	UFUNCTION()
	void UpdateExpose(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		BaseComp.SetRelativeLocation(CurLoc);

		HazeAkComponent.SetRTPCValue("Rtpc_Playroom_Spacestaion_PowerCore_Elevation", CurValue, 0);
	}

	UFUNCTION()
	void FinishExpose()
	{
		HazeAkComponent.HazePostEvent(ElevatorStopEvent);

		if (bDestroyed)
		{
			TargetShutterDoor.CloseShutterDoors(false);
			return;
		}

		if (bGoingUp)
		{
			bTopReached = true;
			OpenShieldTimeLike.Play();
			HazeAkComponent.HazePostEvent(ShieldOpenEvent);
		}
		else
		{
			bBottomReached = true;
		}
	}

	UFUNCTION()
	void UpdateOpenShield(float CurValue)
	{
		float VerticalLoc = FMath::Lerp(-415.f, -800.f, CurValue);
		FVector CurLoc = FVector(ShieldMesh.RelativeLocation.X, ShieldMesh.RelativeLocation.Y, VerticalLoc);
		ShieldMesh.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishOpenShield()
	{
		if (bGoingUp)
			bCoreFullyExposed = true;
	}

	UFUNCTION()
	void DestroyPowerCore()
	{
		NetDestroyPowerCore();
	}

	UFUNCTION(NetFunction)
	void NetDestroyPowerCore()
	{
		if (!bDestroyed)
		{
			OnPowerCoreDestroyed.Broadcast();
			Niagara::SpawnSystemAtLocation(DestroyedEffect, PowerCoreCollision.WorldLocation);
			bDestroyed = true;
			StartLocation = FVector(0.f, 0.f, -100.f);
			System::SetTimer(this, n"HidePowerCore", 3.f, false);
			BP_DestroyPowerCore();
			HazeAkComponent.HazePostEvent(PowerCoreHitEvent);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyPowerCore() {}

	UFUNCTION(BlueprintPure)
	bool IsInactive()
	{
		return !bGoingUp;
	}
}