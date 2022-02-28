	
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackComponent;
import Cake.LevelSpecific.Tree.Queen.QueenArmorComponentHandler;

UCLASS()
class UQueenSpecialAttackCapability : UQueenBaseCapability 
{
	TArray<UQueenSpecialAttackComponent> SpecialAttacks;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Queen = Cast<AQueenActor>(Owner);
		Settings = UQueenSettings::GetSettings(Queen);
		Queen.GetComponentsByClass(SpecialAttacks);
		Queen.DisableRailBlockerSwarms();
		
		Queen.ArmorComponentHandler.OnQueenArmorDetached.AddUFunction(this, n"OnArmorDestroyed");
	}

	UFUNCTION()
	void OnArmorDestroyed(UQueenArmorComponent Armor, int ArmorPieces, bool CauseSpecialAttack)
	{
		if (Queen.QueenPhase != EQueenPhaseEnum::Phase3 && Queen.HasControl())
		{
			if (CauseSpecialAttack)
			{
				SuitableSpecialAttackComp.NetActivateSpecialAttack();	
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if(IsActioning(n"ForceSpecialAttack"))
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"ForceSpecialAttack");

		if (Queen.HasControl())
		{
			SuitableSpecialAttackComp.NetActivateSpecialAttack();
		}
	}

	UQueenSpecialAttackComponent GetSuitableSpecialAttackComp() property
	{
		for(UQueenSpecialAttackComponent i : SpecialAttacks)
		{
			if (i.Order == Queen.QueenSpecialAttackIndex)
			{
				Queen.QueenSpecialAttackIndex++;
				Queen.QueenSpecialAttackIndex %= SpecialAttacks.Num();
				return i;
			}
		}

		return nullptr;
	}
}