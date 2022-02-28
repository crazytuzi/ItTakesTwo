import Vino.PlayerHealth.TimedPlayerDeathEffect;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

class UMurderMicrophoneDeathEffect : UTimedPlayerDeathEffect
{
	void Activate()
	{
		Super::Activate();

		if(Player.IsCody())
		{
			UCymbalComponent CymbalComp = UCymbalComponent::Get(Player);

			if(CymbalComp != nullptr)
			{
				CymbalComp.CurrentCymbal.SetActorHiddenInGame(true);
			}
		}

		Player.SetActorHiddenInGame(true);
	}
	
	void Deactivate()
	{
		Player.SetActorHiddenInGame(false);

		if(Player.IsCody())
		{
			UCymbalComponent CymbalComp = UCymbalComponent::Get(Player);

			if(CymbalComp != nullptr)
			{
				CymbalComp.CurrentCymbal.SetActorHiddenInGame(false);
			}
		}

		Super::Deactivate();
	}
}
