import Cake.Environment.Breakable;
import Vino.Interactions.InteractionComponent;
import Vino.Animations.LockIntoAnimation;
import Vino.Animations.OneShotAnimation;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Crane.JengaTower;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;

class AJengaTowerBreakable : AJengaTowerBase
{
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactedCallbackComp;
	default ImpactedCallbackComp.bCanBeActivedLocallyOnTheRemote = true;

	UPROPERTY(DefaultComponent)
	UGroundPoundThroughComponent GroundPoundThroughComp;

	default Box.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");

	default Height = FVector(0, 0, 600);
	default Scale = 1.25f;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BreakForceFeedback;
		
	float CurrentFadeDelay = 0;
	float FadeDelay = 2.0f;

	TPerPlayer<bool> IsPlayerImpacting;
	bool bTowerKnocked = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Super::ConstructionScript();

		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			JengaPieces[i].Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Super::BeginPlay();
		
		ImpactedCallbackComp.OnActorForwardImpactedByPlayer.AddUFunction(this, n"OnTowerHitStarted");
		ImpactedCallbackComp.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnTowerHitStarted");
		ImpactedCallbackComp.OnActorUpImpactedByPlayer.AddUFunction(this, n"OnTowerHitStarted");
		
		ImpactedCallbackComp.OnUpImpactEndingPlayer.AddUFunction(this, n"OnTowerHitStopped");
		ImpactedCallbackComp.OnDownImpactEndingPlayer.AddUFunction(this, n"OnTowerHitStopped");
		ImpactedCallbackComp.OnForwardImpactEndingPlayer.AddUFunction(this, n"OnTowerHitStopped");

		GroundPoundThroughComp.OnActorGroundPoundedThrough.AddUFunction(this, n"OnGroundPounded");
	}
	UFUNCTION(NotBlueprintCallable)
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		ImpactTower(Player, true);
	}

	UFUNCTION()
	void OnTowerHitStarted(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit)
	{
		IsPlayerImpacting[ImpactingPlayer] = true;
	}

	UFUNCTION()
	void OnTowerHitStopped(AHazePlayerCharacter ImpactingPlayer)
	{
		IsPlayerImpacting[ImpactingPlayer] = false;
	}

	void ImpactTower(AHazePlayerCharacter ImpactingPlayer, bool bGroundPounded = false)
	{
		if (!ImpactingPlayer.HasControl())
			return;			
		
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(ImpactingPlayer);
		NetImpactTower(ImpactingPlayer.ActorLocation, MoveComp.RequestVelocity, bGroundPounded);

		ImpactingPlayer.PlayForceFeedback(BreakForceFeedback, false, true, n"JengaBreak");
	}

	UFUNCTION(NetFunction)
	void NetImpactTower(FVector ImpulseOrigin, FVector PlayerVelocity, bool bGroundPounded)
	{
		bTowerKnocked = true;

		Box.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		UnfreezeInternal();

		if(JengaTowerFallSoundEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(JengaTowerFallSoundEvent, FTransform(GetActorLocation()));

		if (bGroundPounded)
		{
			for (auto JengaPiece : JengaPieces)
			{
				if(JengaPiece.Mesh == nullptr)
					continue;

				FVector ToPlayer = JengaPiece.Mesh.WorldLocation - ImpulseOrigin;

				FVector ImpulseDirection = ToPlayer.GetSafeNormal();
				ImpulseDirection = ToPlayer.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

				float Distance = ToPlayer.Size();
				float ImpulseStrength = 120000.f * (Distance / 400.f);

				JengaPiece.Mesh.AddImpulse(ImpulseDirection * ImpulseStrength);
			}
		}
		else
		{
			for (auto JengaPiece : JengaPieces)
			{
				if(JengaPiece.Mesh == nullptr)
					continue;

				FVector ToPlayer = JengaPiece.Mesh.WorldLocation - ImpulseOrigin;

				FVector ImpulseDirection = PlayerVelocity.GetSafeNormal();

				float Distance = ToPlayer.Size();
				float ImpulseStrength = 240000.f * (1.f - FMath::Clamp((Distance / 375.f), 0.f, 1.f));

				JengaPiece.Mesh.AddImpulse(ImpulseDirection * ImpulseStrength);
			}
		}

		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			DestroyBrick(i);
		}
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		Super::Tick(DeltaTime);

		if (bTowerKnocked)
			return;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (IsPlayerImpacting[Player] && !bTowerKnocked)
			{
				if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash))
					ImpactTower(Player);	
			}
		}
	}
}