import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Queen.CastleEnemyQueenHealingStream;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;

class UCastleEnemyQueenAbilityHealingStream : UHazeCapability
{
	default CapabilityTags.Add(n"QueenAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ACastleEnemy Enemy;
	UChessPieceComponent PieceComp;
	UCastleEnemyBossAbilitiesComponent AbilitiesComp; 

	UPROPERTY()
	TSubclassOf<ACastleEnemyQueenHealingStream> HealingStream;
	ACastleEnemyQueenHealingStream HealingStreamRef;

	ACastleEnemy KingRef;

	UPROPERTY()
	float Duration = 12.f;
	UPROPERTY()
	float DurationCurrent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Enemy = Cast<ACastleEnemy>(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleEnemyBossAbilitiesComponent::GetOrCreate(Owner);	

		if (HealingStream.IsValid())
		{
			HealingStreamRef = Cast<ACastleEnemyQueenHealingStream>(SpawnActor(HealingStream, Owner.ActorLocation));
			HealingStreamRef.AttachToActor(Owner, AttachmentRule = EAttachmentRule::SnapToTarget);
			HealingStreamRef.SetActorRelativeLocation(FVector(0, 0, 150), false, FHitResult(), false);
			HealingStreamRef.SetActorRelativeRotation(FRotator(-90, 0, 0), false, FHitResult(), false);
			HealingStreamRef.Owner = Owner;
		}

		TArray<AActor> ChessPieces;
		Gameplay::GetAllActorsWithTag(n"King", ChessPieces);
		KingRef = Cast<ACastleEnemy>(ChessPieces[0]);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!AbilitiesComp.ShouldStartAbility(this))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TickDuration(DeltaTime);
		FaceKing();
	}

	void TickDuration(float DeltaTime)
	{
		if (DurationCurrent < Duration)
			DurationCurrent += DeltaTime;
	}	

	void FaceKing()
	{
		if (KingRef == nullptr)
			return;

		FRotator DesiredRotation = Math::MakeRotFromX((KingRef.ActorLocation - Owner.ActorLocation).GetSafeNormal());

		Owner.SetActorRotation(DesiredRotation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DurationCurrent >= Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		DurationCurrent = 0.f;

		if (HealingStreamRef != nullptr)
			HealingStreamRef.EnableHealingStream();

		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		if (HealingStreamRef != nullptr)
			HealingStreamRef.DisableHealingStream();

		AbilitiesComp.AbilityFinished();
		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (HealingStreamRef == nullptr)
			return;

		HealingStreamRef.DestroyActor();
		HealingStreamRef = nullptr;
    }
}