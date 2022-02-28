import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class ACastleEnemyQueenHealingStream : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Direction;
	//default Direction.SetRelativeLocation(FVector::UpVector * 120);
	default Direction.SetRelativeRotation(FRotator(90, 0, 0));

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent HealingComponent;

	default SetActorHiddenInGame(true);
    default PrimaryActorTick.bStartWithTickEnabled = false;

	float StreamRadius = 100;
	ACastleEnemy QueenRef;

	UPROPERTY()
	UNiagaraSystem HealingEffect;
	//default HealingComponent.IsActive = false;

	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;
	TPerPlayer<float> DamageTickTimer;

	bool bActive = false;

	UPROPERTY()
	float HealingToEnemy = 100;
	UPROPERTY()
	float HealingToPlayer = 0.4f;

	UPROPERTY()
	float TicksPerSecond = 5;

	UFUNCTION(BlueprintEvent)
	void EnableHealingStream()
	{
		SetActorHiddenInGame(false);
		SetActorTickEnabled(true);
		bActive = true;
	}

	UFUNCTION(BlueprintEvent)
	void DisableHealingStream()
	{
		bActive = false;
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
			TraceToKing(DeltaTime);
	}

	void TraceToKing(float DeltaTime)
	{
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Owner);
		ActorsToIgnore.Add(this);
		
		FHitResult Hit;
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::Pawn);
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		System::SphereTraceSingleForObjects(ActorLocation, ActorLocation + (ActorUpVector * 5000), 150, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
		

		if (Hit.Actor == nullptr)
		{
			float Scale = FMath::Clamp((5000 / 100), 0, 5000);
			SetActorScale3D(FVector(1, 1, Scale));
			//HealingComponent.SetActive(false, false);

		}
		else
		{			
			float Scale = FMath::Clamp(((Hit.ImpactPoint - ActorLocation).Size() / 100), 0.f, 5000.f);
			SetActorScale3D(FVector(1, 1, Scale));
			AffectHitTarget(Hit.Actor, DeltaTime);
			//HealingComponent.SetActive(true, false);

		}
	}

	void AffectHitTarget(AActor OtherActor, float DeltaTime)
	{
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(OtherActor);
		if (CastleEnemy != nullptr)
		{		
			CastleEnemy.SetEnemyHealth(CastleEnemy.Health + (HealingToEnemy * DeltaTime));
			return;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Player.HealPlayerHealth(HealingToPlayer * DeltaTime);
	}
}