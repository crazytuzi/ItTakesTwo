import Peanuts.Position.TransformActor;
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmSkeletalMeshComponent;
import Vino.Movement.MovementSystemTags;

class AThrowPlayerIntoArena : AHazeActor
{
	UPROPERTY()
	ATransformActor TargetActor;

	UPROPERTY(DefaultComponent, RootComponent)
	USwarmSkeletalMeshComponent Swarm;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ThrowPlayerIntoArenaEvent;

	UPROPERTY()
	USwarmAnimationSettingsDataAsset DissolveSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	AHazePlayerCharacter PlayerCharacter;
	bool bIsThrowingPlayer = false;
	FVector StartLerpPosition;
	FVector StartLocation;

	USwarmAnimationSettingsDataAsset TornadoSettings;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		TornadoSettings = Swarm.SwarmAnimSettingsDataAsset;
		DisableActor(this);

		
	}

	UFUNCTION(NetFunction)
	void NetThrowPlayerIntoArena(AHazePlayerCharacter Player)
	{
		if (!bIsThrowingPlayer)
		{
			PlayerCharacter = Player;
			bIsThrowingPlayer = true;
			StartLerpPosition = FVector::UpVector * - 3000;
			AttachToActor(PlayerCharacter, AttachmentRule = EAttachmentRule::SnapToTarget);
			RootComponent.SetRelativeLocation(StartLerpPosition);
			SetActorHiddenInGame(false);
			EnableActor(this);
			
			FHazeCameraBlendSettings BlendSettings;
			Player.ApplyCameraSettings(CameraSettings, BlendSettings, this, EHazeCameraPriority::Maximum);

			UHazeAkComponent::HazePostEventFireForget(ThrowPlayerIntoArenaEvent, RootComponent.GetWorldTransform());
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsThrowingPlayer)
		{
			FVector LerpPosition = FMath::Lerp(RootComponent.RelativeLocation, FVector::ZeroVector, DeltaTime * 1.75f);

			if (LerpPosition.Size() < 300)
			{
				MakePlayerJumpToTarget();
			}
			else
			{
				RootComponent.SetRelativeLocation(LerpPosition);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetToStartpos()
	{
		SetActorLocation(StartLocation);
		Swarm.PlaySwarmAnimation_Internal(TornadoSettings, this, 2.f);
		PlayerCharacter.UnblockCapabilities(MovementSystemTags::Grinding, this);
		DisableActor(this);
	}

	void MakePlayerJumpToTarget()
	{
		FHazeJumpToData JumpData;
		JumpData.TargetComponent = TargetActor.RootComponent;
		JumpData.AdditionalHeight = 1000;
		PlayerCharacter.BlockCapabilities(MovementSystemTags::Grinding, this);
		
		JumpTo::ActivateJumpTo(PlayerCharacter, JumpData);
		bIsThrowingPlayer = false;
		System::SetTimer(this, n"DissolveSwarm", 1, false);
		PlayerCharacter.ClearCameraSettingsByInstigator(this);

		
	}

	UFUNCTION(NotBlueprintCallable)
	void DissolveSwarm()
	{
		Swarm.PlaySwarmAnimation_Internal(DissolveSettings, this, 0.2f);
		Swarm.DetachFromParent();
		System::SetTimer(this, n"ResetToStartpos", 2, false);

		
	}
}