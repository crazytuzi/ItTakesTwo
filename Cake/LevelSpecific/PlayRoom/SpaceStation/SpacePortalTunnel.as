import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalComponent;

UCLASS(Abstract)
class ASpacePortalTunnel : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TunnelRoot;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UStaticMeshComponent TunnelMesh;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	UHazeCameraComponent CamComp;

	UPROPERTY(DefaultComponent, Attach = TunnelRoot)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY()
	EHazePlayer AssignedPlayer;

	UPROPERTY()
	AActor Planet;

	AHazePlayerCharacter Player;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FadeEffectTimeLike;
	default FadeEffectTimeLike.Duration = 1.f;

	bool bFadingUp = false;
	bool bResetSpeedShimmer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FadeEffectTimeLike.BindUpdate(this, n"UpdateFadeEffect");
		FadeEffectTimeLike.BindFinished(this, n"FinishFadeEffect");

		if (AssignedPlayer == EHazePlayer::Cody)
		{
			Player = Game::GetCody();
		}
		else
		{
			Player = Game::GetMay();
		}

		TunnelMesh.SetRenderedForPlayer(Player.OtherPlayer, false);
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void PutPlayerInTunnel()
	{
		SetActorHiddenInGame(false);
		Player.TeleportActor(PlayerAttachmentPoint.WorldLocation, PlayerAttachmentPoint.WorldRotation);
		StartRotatingEarth();
	}

	void RemovePlayerFromTunnel()
	{
		if (Planet != nullptr)
		{
			URotatingMovementComponent RotComp = Cast<URotatingMovementComponent>(Planet.GetComponentByClass(URotatingMovementComponent::StaticClass()));

			if (RotComp != nullptr)
			{
				RotComp.RotationRate = FRotator(0.f, 0.f, 0.f);
			}
		}

		SetActorHiddenInGame(true);
	}

	void StartRotatingEarth()
	{
		if (Planet != nullptr)
		{
			URotatingMovementComponent RotComp = Cast<URotatingMovementComponent>(Planet.GetComponentByClass(URotatingMovementComponent::StaticClass()));

			if (RotComp != nullptr)
			{
				RotComp.RotationRate = FRotator(-30.f, 0.f, 0.f);
			}
		}
	}

	UFUNCTION()
	void ActivateTunnelCamera()
	{
		Player.ActivateCamera(CamComp, 0.f, this, EHazeCameraPriority::High);
		FadeDownEffect();
	}

	void FadeUpEffect()
	{
		bResetSpeedShimmer = true;
		bFadingUp = true;
		FadeEffectTimeLike.SetPlayRate(1.5f);
		FadeEffectTimeLike.ReverseFromEnd();
	}

	void FadeDownEffect()
	{
		bFadingUp = false;
		FadeEffectTimeLike.SetPlayRate(1.5f);
		FadeEffectTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateFadeEffect(float CurValue)
	{
		
	}

	UFUNCTION()
	void FinishFadeEffect()
	{
		if (bFadingUp)
			FadeDownEffect();
	}
}