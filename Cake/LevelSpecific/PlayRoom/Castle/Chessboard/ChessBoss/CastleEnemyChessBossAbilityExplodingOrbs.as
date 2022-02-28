import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyChessBossExplodingOrb;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleChessBossAbilitiesComponent;

class UCastleEnemyChessBossAbilityExplodingOrbs : UHazeCapability
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	ACastleEnemy OwningBoss;
	UChessPieceComponent PieceComp;
	UCastleChessBossAbilitiesComponent AbilitiesComp;

	FChessBossExplodingOrbLocations ExplodingOrbLocations;

	UPROPERTY()
	const float Cooldown = 16.f;

	UPROPERTY()
	TSubclassOf<ACastleChessBossExplodingOrb> ExplodingOrbType;

	int MaxNumberOfOrbs = 2;
	int NumberOfOrbs = 2;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningBoss = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleChessBossAbilitiesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceComp.State != EChessPieceState::Fighting)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceComp.bIsMoving)
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Cooldown)
			return EHazeNetworkActivation::DontActivate;

		if (AbilitiesComp.CooldownBetweenAbilitiesCurrent > 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ExplodingOrbLocations.Locations.Empty();

		for (int Index = 0; Index < NumberOfOrbs; Index++)
		{
			ExplodingOrbLocations.Locations.Add(FVector2D(GetRandomCoordinateElement(), GetRandomCoordinateElement()));
		}

		ActivationParams.AddStruct(n"SpawnLocations", ExplodingOrbLocations);		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);

		ActivationParams.GetStruct(n"SpawnLocations", ExplodingOrbLocations);

		for (int Index = 0; Index < ExplodingOrbLocations.Locations.Num(); Index++)
		{
			SpawnOrb(ExplodingOrbLocations.Locations[Index]);
		}

		AbilitiesComp.AbilityActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		NumberOfOrbs = FMath::Min(NumberOfOrbs + 1, MaxNumberOfOrbs);

		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

	}

	void SpawnOrb(FVector2D TileCoordinate)
	{
		ACastleChessBossExplodingOrb SpawnedOrb = Cast<ACastleChessBossExplodingOrb>(SpawnActor(ExplodingOrbType, Owner.ActorLocation));
		SpawnedOrb.StartOrb(PieceComp.Chessboard, TileCoordinate);
	}

	float GetRandomCoordinateElement()
	{
		int Element = FMath::RandRange(0.f, PieceComp.Chessboard.GridSize.X);
		return Element;
	}
}

struct FChessBossExplodingOrbLocations
{
	TArray<FVector2D> Locations;
}