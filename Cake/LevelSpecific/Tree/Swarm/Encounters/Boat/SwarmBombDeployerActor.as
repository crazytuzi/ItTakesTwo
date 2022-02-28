
import Cake.LevelSpecific.Tree.Swarm.Encounters.Boat.SwarmDeployedBombComponent;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Peanuts.Triggers.ActorTrigger;

class ASwarmBombDeployerActor : AActorTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::Yellow);
    default bGenerateOverlapEventsDuringLevelStreaming = false;
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default TriggerOnActorClasses.Add(TSubclassOf<AHazeActor>(ASwarmActor::StaticClass()));

	UPROPERTY(Category = "BombDeployer")
	TSubclassOf<AHazeActor> BombActorToSpawn;

	UPROPERTY(Category = "BombDeployer")
	TSubclassOf<USwarmDeployedBombComponent> DeployedBombComponent;

	UPROPERTY(Category = "BombDeployer")
	AActor SplineActorAroundBoat;

	UPROPERTY(Category = "BombDeployer")
	AActor SplineActorForBombing;

	UPROPERTY(Category = "BombDeployer|BomberBehaviour")
	UHazeCapabilitySheet BomberBehaviourSheet = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Swarm/SwarmBehaviourSheets/HitAndRun/Airplane_HitAndRun_SwarmBehaviour.Airplane_HitAndRun_SwarmBehaviour");

	UPROPERTY(Category = "BombDeployer|BomberBehaviour")
	USwarmBehaviourBaseSettings BomberBehaviourSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Swarm/SwarmBehaviourSettings/HitAndRun/Airplane_HitAndRun_SwarmBehaviourSettings.Airplane_HitAndRun_SwarmBehaviourSettings");

	UPROPERTY(Category = "BombDeployer|AttackerBehaviour")
	UHazeCapabilitySheet AttackBehaviourSheet = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Swarm/SwarmBehaviourSheets/HitAndRun/Default_HitAndRun_SwarmBehaviour.Default_HitAndRun_SwarmBehaviour");

	UPROPERTY(Category = "BombDeployer|AttackerBehaviour")
	USwarmBehaviourBaseSettings AttackBehaviourSettings = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/Swarm/SwarmBehaviourSettings/HitAndRun/Default_HitAndRun_SwarmBehaviourSettings.Default_HitAndRun_SwarmBehaviourSettings");

	UPROPERTY(Category = "BombDeployer")
	TArray<FSwarmBomb> Bombs;

	ASwarmActor SwarmBomber = nullptr;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"HandleOnActorEnter");
	}

	UFUNCTION()
	void HandleOnActorEnter(AHazeActor Actor)
	{
		ASwarmActor Swarm = Cast<ASwarmActor>(Actor);
		SpawnAndAttachBombsToSwarm(Swarm);
		SetActorTickEnabled(true);
		OnActorEnter.Unbind(this, n"HandleOnActorEnter");
		Swarm.SwitchTo(BomberBehaviourSheet, BomberBehaviourSettings, SplineActorForBombing);

		++DebugCounter;
		ensure(DebugCounter == 1);
	}

	int DebugCounter = 0;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (Bombs.Num() <= 0 || HasReachedEndOfSpline())
		{
			FinishBombing();
			return;
		}

		for (int i = Bombs.Num() - 1; i >= 0 ; i--)
		{
			// remove stale references
			if (Bombs[i].DeployedBombComponent == nullptr ||
				Bombs[i].DeployedBombComponent.GetOwner() == nullptr)
			{
				Bombs.RemoveAt(i);
				continue;
			}

			if (ShouldDeployBomb(Bombs[i])) 
			{
				DeployBomb(Bombs[i]);
			}
			else 
			{
				UpdateBombAttachment(Bombs[i]);
			}
		}

    }

	bool HasReachedEndOfSpline() const
	{
		const float FractionOnSpline = SwarmBomber.MovementComp.GetFractionOnSplineForSwarmLocation();
		return FractionOnSpline >= (1.f - KINDA_SMALL_NUMBER);
	}

	void FinishBombing() 
	{
		SwarmBomber.SwitchTo(AttackBehaviourSheet, AttackBehaviourSettings, SplineActorAroundBoat);
		DeployAllRemainingBombs();

		// We can't use disable actor because this is not a hazeactor 
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void SpawnAndAttachBombsToSwarm(ASwarmActor InSwarm)
	{
		for (int i = Bombs.Num() - 1; i >= 0 ; i--)
		{
			FSwarmBomb& Bomb = Bombs[i];

			SwarmBomber = InSwarm;

			auto BombActor = SpawnActor(BombActorToSpawn.Get());

			Bomb.DeployedBombComponent = USwarmDeployedBombComponent::GetOrCreate(BombActor);
			Bomb.DeployedBombComponent.IgnoreActors.AddUnique(InSwarm);
			Bomb.DeployedBombComponent.IgnoreActors.AddUnique(BombActor);
			Bomb.DeployedBombComponent.TargetScale = BombActor.GetActorScale3D();

// 			BombActor.AttachToActor(InSwarm, NAME_None, EAttachmentRule::SnapToTarget);
			UpdateBombAttachment(Bomb);
		}

		// make sure we ignore all bomb siblings, upon deployment
		for (int i = Bombs.Num() - 1; i >= 0 ; i--)
		{
			for (int j = Bombs.Num() - 1; j >= 0 ; j--)
			{
				Bombs[i].DeployedBombComponent.IgnoreActors.Add(Bombs[j].DeployedBombComponent.GetOwner());
			}
		}

	}

	UFUNCTION()
	void DeployAllRemainingBombs() 
	{
		for (int i = Bombs.Num() - 1; i >= 0 ; i--)
		{
			DeployBomb(Bombs[i]);
		}
	}

	UFUNCTION()
	void DeployBomb(FSwarmBomb& InBomb)
	{
		USwarmDeployedBombComponent& DBC = InBomb.DeployedBombComponent;

		DBC.GetOwner().DetachFromActor(EDetachmentRule::KeepWorld);
		DBC.LinearMovement.Velocity = SwarmBomber.MovementComp.TranslationVelocity;

		UpdateBombAttachment(InBomb);

		DBC.Sleep(false);
		DBC.UpdateTargetZ();

		DBC.ApplyNoise(GetActorDeltaSeconds());

		Bombs.Remove(InBomb);
	}

	UFUNCTION(BlueprintPure)
	bool ShouldDeployBomb(const FSwarmBomb& InBomb)
	{
		const float Frac = SwarmBomber.MovementComp.GetFractionOnSplineForCustomLocation(
			SwarmBomber.SkelMeshComp.CenterOfParticles
		);

		return Frac >= InBomb.DeployAfterSplineFraction;
	}

	// We have to use this instead of normal attachment because the location
	// of the swarm center will constantly change - and change very drastically once 
	// the particles start dying. 
	UFUNCTION()
	void UpdateBombAttachment(FSwarmBomb& InBomb) 
	{
		//////////////////////////////////////////////////////////////////////////
		// FTransform editor details is broken in 4.22.
		//////////////////////////////////////////////////////////////////////////

//  		FTransform AttachmentTransform = SwarmBomber.MovementComp.SwarmTransform;
// 		AttachmentTransform.SetLocation(SwarmBomber.MovementComp.ParticleCenterLocation);
// 		AttachmentTransform.ConcatenateRotation(InBomb.StartRelativeTransform.GetRotation());
// 		const FVector SwarmLocationWithOffset= AttachmentTransform.TransformPositionNoScale(
// 			InBomb.StartRelativeTransform.GetTranslation()
// 		);
// 		AttachmentTransform.SetLocation(SwarmLocationWithOffset);
// 		AttachmentTransform.SetScale3D(InBomb.StartRelativeTransform.GetScale3D());

		FTransform AttachmentTransform = SwarmBomber.MovementComp.DesiredSwarmActorTransform;
		AttachmentTransform.SetLocation(SwarmBomber.SkelMeshComp.CenterOfParticles);
		AttachmentTransform.ConcatenateRotation(FQuat(InBomb.StartRelativeRotation));
		const FVector SwarmLocationWithOffset= AttachmentTransform.TransformPositionNoScale(
			InBomb.StartRelativeLocation
		);
		AttachmentTransform.SetLocation(SwarmLocationWithOffset);
		AttachmentTransform.SetScale3D(InBomb.StartRelativeScale);

		InBomb.DeployedBombComponent.GetOwner().SetActorTransform(AttachmentTransform);
		InBomb.DeployedBombComponent.Scale.Value = AttachmentTransform.GetScale3D();
		InBomb.DeployedBombComponent.LinearMovement.Value = AttachmentTransform.GetLocation();
		InBomb.DeployedBombComponent.AngularMovement.Value = AttachmentTransform.GetRotation().Rotator();
	}
}

struct FSwarmBomb 
{
	// At what fraction of the spline should we drop the bomb? 
	UPROPERTY()
	float DeployAfterSplineFraction = 0.f;

// 	UPROPERTY()
// 	FTransform StartRelativeTransform = FTransform(FRotator(0.f, 0.f, 180.f), FVector(0.f, 0.f, 100.f));

	UPROPERTY()
	FVector StartRelativeLocation = FVector(0.f, 0.f, 200.f);

	UPROPERTY()
	FRotator StartRelativeRotation = FRotator(-180.f, 0.f, 0.f);

	UPROPERTY()
	FVector StartRelativeScale = FVector(1.f, 1.f, 1.f);

	UPROPERTY(NotEditable)
	USwarmDeployedBombComponent DeployedBombComponent = nullptr;

	bool opEquals(const FSwarmBomb& Other) const
	{
		return DeployedBombComponent == Other.DeployedBombComponent;
	}

	bool opEquals(FSwarmBomb& Other) const
	{
		return DeployedBombComponent == Other.DeployedBombComponent;
	}
};








