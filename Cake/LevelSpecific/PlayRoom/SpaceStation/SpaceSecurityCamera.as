import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Vino.Camera.Components.WorldCameraShakeComponent;

class ASpaceSecurityCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CameraBase;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UStaticMeshComponent CameraMesh;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UArrowComponent ForwardDirection;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UWorldCameraShakeComponent CamShakeComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Anim;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroySystem;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpaceSecurityCameraAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSpaceSecurityCameraAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySpaceSecurityCameraDestroyAudioEvent;

	FRotator CurrentRotation;

	bool bTrackingPlayers = true;

	float CurrentCameraYaw;
    float CurrentCameraPitch;
	float LastRotationDelta;
	float RotationVelocityAlpha = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentRotation = CameraRoot.WorldRotation;

		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");
		InteractionComp.DisableForPlayer(Game::GetMay(), n"May");
		InteractionComp.DisableForPlayer(Game::GetCody(), n"Size");

		ChangeSizeComp.OnCharacterChangedSize.AddUFunction(this, n"ChangedSize");
		HazeAkComp.HazePostEvent(PlaySpaceSecurityCameraAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Player.PlayEventAnimation(Animation = Anim);
		
		InteractionComp.Disable(n"Destroyed");

		FHazeAnimNotifyDelegate HitDelegate;
		HitDelegate.BindUFunction(this, n"HitCamera");

		Player.BindOrExecuteOneShotAnimNotifyDelegate(Anim, UAnimNotify_Interaction::StaticClass(), HitDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void HitCamera(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelComp, UAnimNotify Notify)
	{
		bTrackingPlayers = false;
		SetActorTickEnabled(false);
		Niagara::SpawnSystemAtLocation(DestroySystem, CameraRoot.WorldLocation);
		BP_HitCamera();
		RotationVelocityAlpha = 0.f;
		HazeAkComp.HazePostEvent(StopSpaceSecurityCameraAudioEvent);
		HazeAkComp.HazePostEvent(PlaySpaceSecurityCameraDestroyAudioEvent);

		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationDestroyCameraCody");

		ForceFeedbackComp.Play();
		CamShakeComp.Play();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HitCamera() {}

	UFUNCTION(NotBlueprintCallable)
	void ChangedSize(FChangeSizeEventTempFix NewSize)
	{
		if (NewSize.NewSize == ECharacterSize::Large)
		{
			InteractionComp.EnableForPlayer(Game::GetCody(), n"Size");
		}
		else if (NewSize.NewSize == ECharacterSize::Medium)
		{
			InteractionComp.DisableForPlayer(Game::GetCody(), n"Size");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bTrackingPlayers)
			return;

		float ClosestDistance = BIG_NUMBER;
		AHazePlayerCharacter ClosestPlayer;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			float Dist = Player.GetHorizontalDistanceTo(this);

			FVector Dir = Player.Mesh.GetSocketLocation(n"Head") - CameraRoot.WorldLocation;
			Dir.Normalize();
			float Dot = Dir.DotProduct(ActorForwardVector);

			if (Dist < ClosestDistance && Dot > 0.f)
			{
				ClosestDistance = Dist;
				ClosestPlayer = Player;
			}
		}

		if (ClosestDistance >= 5000.f)
		{
			RotationVelocityAlpha = 0.f;
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SpaceSecurityCamera_Movement", 0.f);
			return;
		}

		FVector DirToClosestPlayer = ClosestPlayer.Mesh.GetSocketLocation(n"Head") - CameraRoot.WorldLocation;
		DirToClosestPlayer.Normalize();
		FRotator Rot = DirToClosestPlayer.Rotation();

		Rot.Yaw = FMath::Clamp(Rot.Yaw, ActorRotation.Yaw - 90.f, ActorRotation.Yaw + 90.f);
		Rot.Pitch = FMath::Clamp(Rot.Pitch, -45.f, 25.f);

		CurrentRotation = FMath::RInterpTo(CurrentRotation, Rot, DeltaTime, 3.f);
		CameraRoot.SetWorldRotation(CurrentRotation);

		CurrentCameraYaw = CameraRoot.WorldRotation.Yaw * -1.f;
		CurrentCameraPitch = CameraRoot.WorldRotation.Pitch;
		float RotationDelta = (CurrentCameraYaw + CurrentCameraPitch) - LastRotationDelta;
		LastRotationDelta = CurrentCameraYaw + CurrentCameraPitch;

		RotationVelocityAlpha = FMath::GetMappedRangeValueClamped(FVector2D(0.2f, 3.f), FVector2D(0.f, 1.f), FMath::Abs(RotationDelta));
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SpaceSecurityCamera_Movement", RotationVelocityAlpha);
	}
}