import Cake.LevelSpecific.Tree.Queen.QueenArmorComponentHandler;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class UQueenHealthBarCapability : UHazeCapability
{
	UQueenArmorComponentHandler ArmorHandler;
	AQueenActor Queen;
	UBossHealthBarWidget BossHealth;
	bool bDrawHealth;
	bool bSetPhase3;
	float QueenBossHealth;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Queen = Cast<AQueenActor>(Owner);
		ArmorHandler = UQueenArmorComponentHandler::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"RemoveArmourHealthbar"))
		{
        	return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"RemoveArmourHealthbar"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CreateWidget();
		Queen.OnArmourTakenDamage.AddUFunction(this, n"HandleDamageTaken");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Widget::RemoveFullscreenWidget(BossHealth);
		Queen.OnArmourTakenDamage.Unbind(this, n"HandleDamageTaken");
    }

	UFUNCTION()
	void CreateWidget()
	{
		BossHealth = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(ArmorHandler.BossHealthbarWidgetClass, EHazeWidgetLayer::Gameplay));

		float MaxHealth = 0;
		QueenBossHealth = 0;

		for (UQueenArmorComponent ArmorComp : ArmorHandler.TotalArmorComponents)
		{
			QueenBossHealth += ArmorComp.HP / ArmorComp.MaxHealth;
			MaxHealth ++;
		}
		
		FText BossName = NSLOCTEXT("WaspQueen", "Name", "Wasp Queen");
		BossHealth.InitBossHealthBar(BossName, MaxHealth);
		BossHealth.SnapHealthTo(QueenBossHealth);
	}

	UFUNCTION()
	void HandleDamageTaken(
		FVector HitLocation,
		USceneComponent HitComponent,
		FName HitSocket,
        float DamageTaken)
	{
		if (HasControl())
		{
			float NewHealth = 0.f;

			for (UQueenArmorComponent ArmorComp : ArmorHandler.TotalArmorComponents)
			{
				NewHealth += ArmorComp.HP / ArmorComp.MaxHealth;
			}

			NewHealth / ArmorHandler.TotalArmorComponents.Num();

			float Diff = QueenBossHealth - NewHealth;
			QueenBossHealth = FMath::Clamp(NewHealth, 0.1f, 999999999.f);
			NetSetQueenhealth(QueenBossHealth);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetQueenhealth(float NewHealth)
	{
		BossHealth.SetHealthAsDamage(NewHealth);
	}
}