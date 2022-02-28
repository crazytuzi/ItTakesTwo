import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;

UCLASS(Abstract)
class UChessBossAbility : UHazeCapability
{
	default CapabilityTags.Add(n"ChessBossAbility");

	default CapabilityDebugCategory = n"Level Specific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACastleEnemy OwningBoss;
	UChessPieceComponent PieceComp;
	UCastleEnemyBossAbilitiesComponent AbilitiesComp;

	UPROPERTY()
	float Cooldown = 4.f;
	float CurrentCooldown = 0.f;

	UPROPERTY()
	FBossAbility BossAbility;
	default BossAbility.AbilityType = Class;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningBoss = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleEnemyBossAbilitiesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (CurrentCooldown > 0.f)
			CurrentCooldown -= DeltaTime;

		if (ShouldActivateAbility())
			AbilitiesComp.AddAbilityToQueue(BossAbility);
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (AbilitiesComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (!AbilitiesComp.ShouldStartAbility(this))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ShouldDeactivateAbility())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AbilitiesComp.AbilityFinished();
	}

	UFUNCTION()
	bool ShouldActivateAbility() const
	{
		if (CurrentCooldown <= 0.f)
			return true;

		return false;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		return false;
	}
}