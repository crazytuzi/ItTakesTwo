import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdTeam;
import Cake.LevelSpecific.Music.Classic.KeyBirdBehaviorManager;

struct FPotentialKeyBirdTarget
{
	AKeyBird KeyBirdTarget = nullptr;
	float DistanceSq = 0.0f;
}

UCLASS(abstract)
class UKeyBirdEvaluationBaseCapability : UHazeCapability
{
	AKeyBirdCombatArea CombatArea;
	float Elapsed = 0.0f;
	bool bRun = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		CombatArea = Cast<AKeyBirdCombatArea>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!CombatArea.bActivateManager)
			return EHazeNetworkActivation::DontActivate;

		UHazeAITeam TempKeyTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");
		UHazeAITeam TempKeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam");

		if(TempKeyTeam == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(TempKeyBirdTeam == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		UHazeAITeam TempKeyTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");
		UHazeAITeam TempKeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam");

		if(TempKeyTeam == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TempKeyBirdTeam == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Elapsed -= DeltaTime;

		if(Elapsed < 0.0f)
		{
			RandomizeFrequenzy();
			bRun = true;
		}
	}

	AKeyBird EvaluateTargets(AHazeActor TargetActor)
	{
		if(!bRun)
			return nullptr;

		bRun = false;

		UKeyBirdTeam KeyBirdTeam = Cast<UKeyBirdTeam>(HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam"));

		if(KeyBirdTeam == nullptr)
			return nullptr;

		if(!HasMaxOfCounter(KeyBirdTeam))
			return nullptr;

		TSet<AHazeActor> AllBirds = KeyBirdTeam.GetMembers();
		AKeyBird CurrentKeyBird = nullptr;

		float SmallestValue = Math::MaxFloat;
		TArray<FPotentialKeyBirdTarget> PotentialTargets;

		for(AHazeActor KeyBirdActor : AllBirds)
		{
			AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

			if(!KeyBird.HasControl())
				continue;
			if(KeyBird.CurrentState != EKeyBirdState::RandomMovement)
				continue;
			if(KeyBird.IsDead())
				continue;
			if(!KeyBird.CanChangeTarget())
				continue;
			if(KeyBird.IsHoldingKey())
				continue;
			if(!KeyBird.IsPointInsideCombatArea(TargetActor.ActorLocation))
				continue;
			if(!KeyBird.IsKeyBirdEnabled())
				continue;
				
			FPotentialKeyBirdTarget PotentialTarget;
			PotentialTarget.KeyBirdTarget = KeyBird;
			PotentialTarget.DistanceSq = KeyBird.GetSquaredDistanceTo(TargetActor);
			PotentialTargets.Add(PotentialTarget);
		}

		for(FPotentialKeyBirdTarget Target : PotentialTargets)
		{
			float DistanceBetween = FMath::Abs(FMath::Square(GetAverageDistance()) - Target.DistanceSq);
			if(DistanceBetween < SmallestValue)
			{
				SmallestValue = DistanceBetween;
				CurrentKeyBird = Target.KeyBirdTarget;
			}
		}

		return CurrentKeyBird;
	}

	bool HasMaxOfCounter(UKeyBirdTeam KeyBirdTeam) const
	{
		return false;
	}

	void RandomizeFrequenzy()
	{
		Elapsed = FMath::RandRange(GetFrequenzyMin(), GetFrequenzyMax());
	}

	float GetFrequenzyMin() const
	{
		return 0.0f;
	}

	float GetFrequenzyMax() const
	{
		return 0.0f;
	}

	EKeyBirdTeamCounterType GetCounterType() const
	{
		return EKeyBirdTeamCounterType::None;
	}

	float GetAverageDistance() const
	{
		return 0.0f;
	}

	bool IsPointInsideCombatArea(FVector Point) const
	{
		return CombatArea.IsInsideCombatArea(Point);
	}
}
