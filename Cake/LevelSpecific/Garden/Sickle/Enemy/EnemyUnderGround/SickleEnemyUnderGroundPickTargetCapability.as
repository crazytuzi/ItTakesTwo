import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyPickTargetCapability;

class USickleEnemyUnderGroundPickTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;
	
	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;

	const float OutSideAgainRange = 200.f;
	TArray<float> HidingTimes;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(Owner);
		HidingTimes.Add(0.f);
		HidingTimes.Add(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{		 
		auto Cody = Game::GetCody();
		auto May = Game::GetMay();

		const float CodyDetectDistance = AiComponent.GetDetectDistance(Cody);
		const float MayDetectDistance = AiComponent.GetDetectDistance(May);

        if(Cody.HasControl())
        {
            if(ChangeActivatorValue(Cody, AiComponent.bCodyWantsMeToHide, CodyDetectDistance, DeltaTime))
            {
                NetSetCodyWantsMeToHide(!AiComponent.bCodyWantsMeToHide);
            }
        }
       
        if(May.HasControl())
        {
            if(ChangeActivatorValue(May, AiComponent.bMayWantsMeToHide, MayDetectDistance, DeltaTime))
            {
                NetSetMayWantsMeToHide(!AiComponent.bMayWantsMeToHide);
            }
        }

#if EDITOR
        if(AiOwner.bHazeEditorOnlyDebugBool)
        {
            FVector UpVector = AiComponent.WorldUp;
            FVector From = AiOwner.GetActorLocation() + (UpVector * 100.f);
            FVector To = From - (UpVector * 800.f);

            if(!AiComponent.bCodyWantsMeToHide)
                System::DrawDebugCylinder(From, To, CodyDetectDistance, LineColor = FLinearColor::Green);
            else
                System::DrawDebugCylinder(From, To, CodyDetectDistance + OutSideAgainRange, LineColor = FLinearColor::Green);

            if(!AiComponent.bMayWantsMeToHide)
                System::DrawDebugCylinder(From, To, MayDetectDistance, LineColor = FLinearColor::Blue);
            else
                System::DrawDebugCylinder(From, To, MayDetectDistance + OutSideAgainRange, LineColor = FLinearColor::Blue);
        }
#endif
	}

	bool ChangeActivatorValue(AHazePlayerCharacter Player, bool IsHiding, float HideDistance, float DeltaTime)
    {
		const float StayHiddenTime = 1.f;
        float PlayerDistance = Player.GetHorizontalDistanceTo(AiOwner);

		float& HidingTime = Player.IsCody() ? HidingTimes[0] : HidingTimes[1];

        // We need more distance when we leave to pop up again
        if(IsHiding && PlayerDistance > HideDistance + OutSideAgainRange)
        {
			HidingTime -= DeltaTime;
            return HidingTime <= 0;
        }
        else if(!IsHiding && PlayerDistance <= HideDistance)
        {
			HidingTime = StayHiddenTime;
            return true;
        }

		if(IsHiding)
			HidingTime = StayHiddenTime;

        return false;
    }

    UFUNCTION(NetFunction)
    void NetSetCodyWantsMeToHide(bool bNewStatus)
    {
        AiComponent.bCodyWantsMeToHide = bNewStatus;
    }

    UFUNCTION(NetFunction)
    void NetSetMayWantsMeToHide(bool bNewStatus)
    {
        AiComponent.bMayWantsMeToHide = bNewStatus;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(AiOwner.AreaToMoveIn.PlayersInArea.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(AiOwner.AreaToMoveIn == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(AiOwner.AreaToMoveIn.PlayersInArea.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AiComponent.AttackDelay = AiComponent.DelayToNextAttack;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiOwner.SetPlayerAsTarget(nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AHazePlayerCharacter WantedTarget = PickBestTarget();
		AiOwner.SetPlayerAsTarget(PickBestTarget());
	}

	AHazePlayerCharacter PickBestTarget() const
	{
		if(AiOwner.AreaToMoveIn == nullptr)
			return nullptr;

		auto AvailablePlayers = AiOwner.AreaToMoveIn.PlayersTriggeredCombat;
		if(AvailablePlayers.Num() == 0)
			return nullptr;

		const FVector MyLocation = AiOwner.GetActorLocation();
		float CodyDistAlpha = 2;
		float MayDistAlpha = 2;

		for(auto Player : AvailablePlayers)
		{
			if(Player == nullptr)
				continue;
		
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
			if (HealthComp.bIsDead)
				continue;

			if(Player.IsCody())
			{
				const float CodyDist = Player.GetHorizontalDistanceTo(AiOwner);
				CodyDistAlpha = CodyDist / AiComponent.AttackDistance * 2.f;
			}
			else
			{
				const float MayDist = Player.GetHorizontalDistanceTo(AiOwner);
				MayDistAlpha = MayDist / AiComponent.AttackDistance;
			}
		}

		if(CodyDistAlpha <= 1 && MayDistAlpha > 1)
		{
			return Game::GetCody();
		}
		else if(MayDistAlpha <= 1 && CodyDistAlpha > 1)
		{
			return Game::GetMay();
		}
		else if(MayDistAlpha <= 1 && CodyDistAlpha <= 1)
		{
			return MayDistAlpha * 0.5f <= CodyDistAlpha ? Game::GetMay() : Game::GetCody();
		}
		else
		{
			return nullptr;
		}	
	}
}
