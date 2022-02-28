import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelArea;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelSnowFolk;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelDyingSnowFolk;

class ASnowAngelEventManager : AHazeActor
{
	UPROPERTY()
	TArray<ASnowAngelSnowFolk> SnowFolkArray;

	UPROPERTY()
	TArray<ASnowAngelDyingSnowFolk> SnowFolkDyingArray;
	
	UPROPERTY()
	ASnowAngelArea SnowAngelArea;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASnowAngelSnowFolk SnowFolk : SnowFolkArray)
		{
			SnowFolk.DisableActor(this);
		}

		for (ASnowAngelDyingSnowFolk SnowFolkDying : SnowFolkDyingArray)
		{
			SnowFolkDying.DisableActor(this);
		}

		SnowAngelArea.SetTriggerEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateSnowAngelFolk()
	{
		if (HasControl())
			System::SetTimer(this, n"NetActivateSnowAngelFolk", 1.5f, false);
	}

	UFUNCTION(NetFunction)
	void NetActivateSnowAngelFolk()
	{
		for (ASnowAngelSnowFolk SnowFolk : SnowFolkArray)
		{
			if (SnowFolk.IsActorDisabled(this))
			{
				SnowFolk.EnableActor(this);
				SnowFolk.SpawnDecal();
				SnowFolk.DisableComp.bRenderWhileDisabled = true;
			}
		}
		
		if (SnowFolkDyingArray.Num() > 0)
		{
			for(auto SnowFolkDying : SnowFolkDyingArray)
			{
				if (SnowFolkDying.IsActorDisabled(this))
				{
					SnowFolkDying.EnableActor(this);
					SnowFolkDying.DisableComp.bRenderWhileDisabled = true;
				}
			}
		}

		SnowAngelArea.SetTriggerEnabled(true);
	}
}