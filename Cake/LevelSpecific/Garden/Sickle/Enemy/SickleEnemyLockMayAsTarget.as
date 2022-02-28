import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;

class USickleEnemyLockMayAsTarget : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"PickTarget");

	ASickleEnemy AiOwner;
	USickleEnemyComponentBase AiBaseComponent;

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiBaseComponent = USickleEnemyComponentBase::Get(AiOwner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime){}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"PickTarget", true);
		AiOwner.LockPlayerAsTarget(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"PickTarget", false);
		AiOwner.SetFreeTargeting();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime){}
}