import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.IceCannon.IceCannonBall;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.MinigameReactionSnowFolk.ReactionSnowFolkManager;

UCLASS(Abstract)
class AIceCannonActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCannon;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshLever;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent ProjectileSpawnLoc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Setup")
	TArray<AIceCannonBall> IceCannonBallArray;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraComponent;
	default NiagaraComponent.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 4000.f;
	default DisableComp.SetbRenderWhileDisabled(true);
	
	UPROPERTY(Category = "Setup")
	UFoghornVOBankDataAssetBase VOLevelBank;
	
	UPROPERTY(Category = "Animations")
	UAnimSequence MayLeverSlap;
	
	UPROPERTY(Category = "Animations")
	UAnimSequence CodyLeverSlap;

	UPROPERTY(Category = "Setup")
	TArray<UAnimSequence> ReactionAnimations;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "Setup")
	float DefaultCoolDownTime = 2.5f; 

	UPROPERTY(Category = "Setup")
	AReactionSnowFolkManager ReactionManager;
	
	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> PlayerCamShake;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect PlayerFeedbackForce;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FireAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InteractAudioEvent;

	UPROPERTY()
	FVector StartingScaleCannon;

	UPROPERTY()
	FVector StartingScaleAll;

	float CoolDownTime; 

	bool bIceCannonCanCoolDown;

	bool bIceCannonFired;

	AHazePlayerCharacter PlayerWhoTriggered;

	float MinDist = 2000.f;

	int RandomPlay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"PlayerInteracted");
		
		AddCapability(n"IceCannonOnFiredCapability");
		AddCapability(n"IceCannonLeverActivatedCapability");

		for (AIceCannonBall IceBall : IceCannonBallArray)
		{
			if (!IceBall.IsActorDisabled())
			{
				IceBall.DisableActor(this);
				IceBall.OnDisableIceBallEvent.AddUFunction(this, n"DisableIceBall");
			}
		}

		StartingScaleCannon = MeshCannon.GetRelativeScale3D();
		StartingScaleAll = GetActorScale3D();

		InteractionComp.Disable(n"BellNotRung");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIceCannonCanCoolDown)
		{
			CoolDownTime -= DeltaTime;

			if (CoolDownTime <= 0.f)
			{
				CooldownComplete();
				bIceCannonCanCoolDown = false;
				bIceCannonFired = false;
			}
		}
	}

	UFUNCTION()
	void EnableIceCannon()
	{
		InteractionComp.EnableAfterFullSyncPoint(n"BellNotRung");
	}

	UFUNCTION()
	void PlayerFeedback(AHazePlayerCharacter Player)
	{
		float PlayerDist = (Player.ActorLocation - ActorLocation).Size();

		if (PlayerDist <= MinDist)
		{
			Player.PlayCameraShake(PlayerCamShake);
			Player.PlayForceFeedback(PlayerFeedbackForce, false, false, n"ShuffleBoard FF");
		}
	}

	UFUNCTION()
	void PlayerInteracted(UInteractionComponent InteractionComp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"IceCannon in use");

		System::SetTimer(this, n"FireCannon", 0.6f, false);

		PlayerWhoTriggered = Player;

		CoolDownTime = DefaultCoolDownTime;
		bIceCannonCanCoolDown = true;
		Player.PlayerHazeAkComp.HazePostEvent(InteractAudioEvent);

		if (HasControl())
		{
			if (RandomPlay == 0)
			{
				NetVOPlay(Player);
				RandomPlay = FMath::RandRange(1, 2);
			}
			else
			{
				RandomPlay--;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetVOPlay(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownSnowCannonActivateMay");
		else
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBSnowGlobeTownSnowCannonActivateCody");
	}

	UFUNCTION()
	void CooldownComplete()
	{
		InteractionComp.Enable(n"IceCannon in use");
	}

	UFUNCTION(BlueprintEvent)
	void BP_CannonReaction() {}

	UFUNCTION()
	void FireCannon()
	{
		bIceCannonFired = true;
		
		HazeAkComp.HazePostEvent(FireAudioEvent);
		
		BP_CannonReaction();

		PlayerFeedback(Game::May);
		PlayerFeedback(Game::Cody);

		for (AIceCannonBall IceBall : IceCannonBallArray)
		{
			if (IceBall.IsActorDisabled())
			{
				IceBall.EnableActor(this);
				IceBall.InitiateIceCannonBall(ProjectileSpawnLoc.WorldLocation, ProjectileSpawnLoc.WorldRotation.ForwardVector);
				IceBall.OnIceBallExplodedEvent.AddUFunction(this, n"IceBallCrowdReaction");
				NiagaraComponent.Activate(true);
				return;
			}
		}
	}

	UFUNCTION()
	void DisableIceBall(AIceCannonBall IceBall)
	{
		if (!IceBall.IsActorDisabled())
			IceBall.DisableActor(this);
	}

	UFUNCTION()
	void IceBallCrowdReaction()
	{
		ReactionManager.ActivateReactions();
		ReactionManager.ActivateRotations(ReactionManager.ActorLocation, 1.5f);
	}
}