import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList;

import void TriggerCastlePlayerTakeDamage(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent";
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleFreezableComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;

import void SetPlayerHiddenFromEnemies(AHazePlayerCharacter Player, bool bHiddenFromEnemies) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent";

struct FCastlePlayerDamageEvent
{
    UPROPERTY()
    AHazeActor DamageSource;
    UPROPERTY()
    float DamageDealt = 0.f;
    UPROPERTY()
    FVector DamageLocation;
    UPROPERTY()
    FVector DamageDirection;
	UPROPERTY()
    float DamageSpeed = 50.f;
    UPROPERTY()
    bool bIsCritical = false;
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

    bool HasDirection() const
    {
        return !DamageDirection.IsNearlyZero();
    }
};

UCLASS(Abstract)
class UCastleDamageEffect : UPlayerDamageEffect
{
    UPROPERTY(BlueprintReadOnly, NotEditable)
    FCastlePlayerDamageEvent DamageEvent;

	default bPlayUniversalDamageEffect = false;
};

class UDummyCastleDamageEffect : UCastleDamageEffect
{
	void Activate()
	{
		Super::Activate();
		FinishEffect();
	}
};

UFUNCTION()
void DamageCastlePlayer(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
{
    TriggerCastlePlayerTakeDamage(Player, DamageEvent);
}

UFUNCTION(Category = "Castle")
void SetHidePlayerFromCastleEnemies(AHazePlayerCharacter Player, bool bHiddenFromEnemies)
{
	SetPlayerHiddenFromEnemies(Player, bHiddenFromEnemies);
}

UFUNCTION(BlueprintPure)
bool IsPlayerNearbyEnemies(AHazePlayerCharacter Player)
{
	FVector Origin = Player.ActorLocation;
	float MaxDist = FMath::Square(3000.f);
    for (ACastleEnemy CastleEnemy : GetAllCastleEnemies())
    {
        if (CastleEnemy == nullptr)
            continue;

		float Distance = CastleEnemy.ActorLocation.DistSquared(Origin);
		if (Distance > MaxDist)
			continue;

		return true;
    }

	return false;
}

UFUNCTION(BlueprintPure)
TArray<ACastleEnemy> GetCastleEnemiesInSphere(FVector Origin, float Radius = 250.f)
{
    TArray<ACastleEnemy> ValidCastleEnemies;

    for (ACastleEnemy CastleEnemy : GetAllCastleEnemies())
    {
        if (CastleEnemy == nullptr)
            continue;

		float Distance = CastleEnemy.ActorLocation.DistSquared(Origin);
		if (Distance > FMath::Square(Radius + CastleEnemy.CapsuleComponent.ScaledCapsuleRadius))
			continue;

		ValidCastleEnemies.AddUnique(CastleEnemy);                
    }

    return ValidCastleEnemies;        
}

UFUNCTION(BlueprintPure)
TArray<ACastleEnemy> GetCastleEnemiesInCone(FVector Origin, FRotator Rotation = FRotator::ZeroRotator, float Radius = 250.f, float AngleDegrees = 90.f, bool bShowDebug = false)
{
    TArray<ACastleEnemy> ValidCastleEnemies;

#if EDITOR
    if (bShowDebug)
    {
        FVector Direction = Rotation.ForwardVector;
        Debug::DrawDebugArc(AngleDegrees, Origin, Radius, Direction, Thickness = 3.f, bPersistentLines = true);
    }
#endif

    for (ACastleEnemy CastleEnemy : GetAllCastleEnemies())
    {
        if (CastleEnemy == nullptr)
            continue;

		FVector EnemyLocation;
		CastleEnemy.CapsuleComponent.GetClosestPointOnCollision(Origin, EnemyLocation);

        FVector PlayerToEnemy = EnemyLocation - Origin;
		PlayerToEnemy.Z = 0.f;

		float Distance = PlayerToEnemy.Size();
		if (Distance > Radius)
			continue;
		if (Distance <= 0.f)
		{
            ValidCastleEnemies.AddUnique(CastleEnemy);                
			continue;
		}

		PlayerToEnemy /= Distance;

        float DirectionDot = Rotation.ForwardVector.DotProduct(PlayerToEnemy);
        float Rad = FMath::Acos(DirectionDot);
        float Degrees = FMath::RadiansToDegrees(Rad);

        if (Degrees <= AngleDegrees * 0.5f)
            ValidCastleEnemies.AddUnique(CastleEnemy);                
    }

    return ValidCastleEnemies;        
}

UFUNCTION(BlueprintPure)
TArray<ACastleEnemy> GetCastleEnemiesInBox(FVector StartLocation, FVector EndLocation, float Width = 250.f, bool bShowDebug = false)
{
    TArray<ACastleEnemy> ValidCastleEnemies;

    TArray<FHitResult> HitResults;
    TArray<AActor> ActorsToIgnore;

    FVector TraceLocation;
    TraceLocation = (StartLocation + EndLocation) / 2;

    float HalfLength = (StartLocation - EndLocation).Size() * .5f;
    float HalfWidth = Width * .5f;
    float HalfHeight = 100.f;

    FVector Direction = EndLocation - StartLocation;
    Direction.Normalize();
    FRotator Rotation = Math::MakeRotFromX(Direction);

	FVector BoxExtent(HalfLength, HalfWidth, HalfHeight);
	FTransform BoxTransform(Rotation, TraceLocation);

#if EDITOR
    if (bShowDebug)
    {
		System::DrawDebugBox(TraceLocation, BoxExtent, FLinearColor::White, Rotation, Duration = 1.f);
    }
#endif

    for (ACastleEnemy CastleEnemy : GetAllCastleEnemies())
    {
        if (CastleEnemy == nullptr)
            continue;

		FVector EnemyLocation;
		CastleEnemy.CapsuleComponent.GetClosestPointOnCollision(BoxTransform.Location, EnemyLocation);

		if (!FMath::IsPointInBoxWithTransform(EnemyLocation, BoxTransform, BoxExtent))
			continue;

        ValidCastleEnemies.AddUnique(CastleEnemy);                
    }

    return ValidCastleEnemies;
}

UFUNCTION(BlueprintPure)
TArray<AHazeActor> GetActorsInCone(FVector Origin, FRotator Rotation = FRotator::ZeroRotator, float Radius = 250.f, float AngleDegrees = 90.f, bool bShowDebug = false)
{
    TArray<AHazeActor> ValidActors;
	
	TArray<EObjectTypeQuery> ObjectTypes;
	ObjectTypes.Add(EObjectTypeQuery::Enemy);
	ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
	FHazeTraceParams Trace;
	Trace.InitWithObjectTypes(ObjectTypes);

	Trace.SetOverlapLocation(Origin);
	Trace.SetToSphere(Radius);

	TArray<FOverlapResult> OutOverlaps;
	Trace.OverlapBlockingOnly(OutOverlaps);

#if EDITOR
    if (bShowDebug)
    {
        FVector Direction = Rotation.ForwardVector;
        Debug::DrawDebugArc(AngleDegrees, Origin, Radius, Direction, Thickness = 3.f, bPersistentLines = true);
    }
#endif

	for (FOverlapResult Result : OutOverlaps)
	{
        AHazeActor HazeActor;
        HazeActor = Cast<AHazeActor>(Result.Actor);
        
        if (HazeActor == nullptr)
            continue;

        FVector PlayerToActor = HazeActor.ActorLocation - Origin;
        PlayerToActor.Normalize();

        float DirectionDot = Rotation.ForwardVector.DotProduct(PlayerToActor);
        float Rad = FMath::Acos(DirectionDot);
        float Degrees = FMath::RadiansToDegrees(Rad);

        if (Degrees <= AngleDegrees * 0.5f)
            ValidActors.AddUnique(HazeActor);       
	}

    return ValidActors;        
}

TArray<AHazePlayerCharacter> GetAttackablePlayersInBox(FTransform BoxTransform, FVector BoxExtent, bool bShowDebug = false)
{
	if (bShowDebug)
		System::DrawDebugBox(BoxTransform.Location, BoxExtent, FLinearColor::Red, BoxTransform.Rotation.Rotator());

	TArray<AHazePlayerCharacter> ValidPlayer;
	for (AHazePlayerCharacter Player : Game::GetPlayers())
	{
		if (Player == nullptr)
			continue;

		if (!Player.CanPlayerBeDamaged())
			continue;

		FVector Location;
		Player.CapsuleComponent.GetClosestPointOnCollision(BoxTransform.Location, Location);

		if (!FMath::IsPointInBoxWithTransform(Location, BoxTransform, BoxExtent))
			continue;

		ValidPlayer.AddUnique(Player);
	}

	return ValidPlayer;
}

UFUNCTION(BlueprintPure)
TArray<AHazeActor> GetActorsInBox(FVector StartLocation, FVector EndLocation, float Width = 250.f, bool bShowDebug = false)
{
    TArray<AHazeActor> ValidActors;

    FVector TraceLocation;
    TraceLocation = (StartLocation + EndLocation) / 2;

    float HalfLength = (StartLocation - EndLocation).Size() * .5f;
    float HalfWidth = Width * .5f;
    float HalfHeight = 100.f;

	TArray<EObjectTypeQuery> ObjectTypes;
	ObjectTypes.Add(EObjectTypeQuery::Enemy);
	ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
	FHazeTraceParams Trace;
	Trace.InitWithObjectTypes(ObjectTypes);
	Trace.SetOverlapLocation(TraceLocation);
	Trace.SetToBox(FVector(HalfLength, HalfWidth, HalfHeight));

    FVector Direction = EndLocation - StartLocation;
    Direction.Normalize();
    FQuat Quat = FRotator::MakeFromX(Direction).Quaternion();
	Trace.ShapeRotation = Quat;

	TArray<FOverlapResult> OutOverlaps;
	Trace.OverlapBlockingOnly(OutOverlaps);

#if EDITOR
    if (bShowDebug)
    {
        System::DrawDebugBox(TraceLocation, FVector(HalfLength, HalfWidth, HalfHeight), FLinearColor::Red, Quat.Rotator(), 3.f, 3.f);
    }
#endif




	for (FOverlapResult Result : OutOverlaps)
    {
        AHazeActor HazeActor;
        HazeActor = Cast<AHazeActor>(Result.Actor);
        
        if (HazeActor == nullptr)
            continue;

        ValidActors.AddUnique(HazeActor);                
    }

    return ValidActors;
}

UFUNCTION(BlueprintPure)
TArray<UCastleFreezableComponent> GetFreezableComponentsFromArray(TArray<AHazeActor> HazeActors)
{
	TArray<UCastleFreezableComponent> ValidFreezables;

	for (AHazeActor Actor : HazeActors)
    {
		UCastleFreezableComponent FreezableComponent;
		FreezableComponent = UCastleFreezableComponent::Get(Actor);
       
        if (FreezableComponent == nullptr)
            continue;

        ValidFreezables.AddUnique(FreezableComponent);                
    }

	return ValidFreezables;
}

UFUNCTION(BlueprintPure)
TArray<ACastleEnemy> GetCastleEnemiesFromArray(TArray<AHazeActor> HazeActors)
{
	TArray<ACastleEnemy> ValidCastleEnemies;

	for (AHazeActor Actor : HazeActors)
    {
        ACastleEnemy CastleEnemy;
        CastleEnemy = Cast<ACastleEnemy>(Actor);
        
        if (CastleEnemy == nullptr)
            continue;

        ValidCastleEnemies.AddUnique(CastleEnemy);                
    }

	return ValidCastleEnemies;
}

UFUNCTION(BlueprintPure)
TArray<ACastleEnemy> GetCastleEnemiesInLineOfSight(TArray<ACastleEnemy> CastleEnemies, FVector Origin)
{
	TArray<ACastleEnemy> ValidCastleEnemies;

	for (ACastleEnemy CastleEnemy : CastleEnemies)
    {	
		FVector Destination = CastleEnemy.CapsuleComponent.WorldLocation;

		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::WorldStatic);

		TArray<AActor> ActorsToIgnore;
		FHitResult Hit;		

		System::LineTraceSingleForObjects(Origin, Destination, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

		if (!Hit.bBlockingHit)
			ValidCastleEnemies.Add(CastleEnemy);
    }

	return ValidCastleEnemies;
}

// returns whether the call was a success or not
UFUNCTION()
bool CastleChargeActor(AActor Actor)
{
	if (Actor == nullptr)
		return false;

	UCastleChargableComponent ChargableComponent;
	ChargableComponent = UCastleChargableComponent::Get(Actor);
	
	if (ChargableComponent == nullptr)
		return false;

	ChargableComponent.HitChargableActor();
	
	return true;
}


void ModifyAttackDistanceForCollision(FVector& StartLocation, FVector& EndLocation)
{
	FVector Offset(0.f, 0.f, 50.f);

	TArray<AActor> ActorsToIgnore;
	FHitResult Hit;
	System::LineTraceSingleByProfile(StartLocation + Offset, EndLocation + Offset, 
		n"CastleAttack", false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

	// Don't attack through walls
	if (Hit.bBlockingHit)
	{
		EndLocation = Hit.Location - Offset;
	}
}

bool IsHittableByAttack(AActor SourceActor, AActor TargetActor, FVector TestPosition)
{
	FVector Offset(0.f, 0.f, 50.f);

	TArray<AActor> ActorsToIgnore;
	FHitResult Hit;
	System::LineTraceSingleByProfile(SourceActor.ActorLocation + Offset, TestPosition + Offset, 
		n"CastleAttack", false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

	if (Hit.bBlockingHit)
		return Hit.Actor == TargetActor;

	return true;
}