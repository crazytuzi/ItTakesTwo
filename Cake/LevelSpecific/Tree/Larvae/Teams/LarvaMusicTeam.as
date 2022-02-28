import Vino.Audio.Music.MusicIntensityLevelComponent;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspMusicTeam;

class ULarvaMusicTeam : UWaspMusicTeam
{
	void BindDelegates(AHazeActor Enemy)
	{
		// Bind relevant delegates to update music intensity.
		ULarvaBehaviourComponent BehaviourComp = ULarvaBehaviourComponent::Get(Enemy);
		if (BehaviourComp != nullptr)
		{
			BehaviourComp.OnJustHatched.AddUFunction(this, n"ReportThreat");
			BehaviourComp.OnDisabled.AddUFunction(this, n"ReportThreatOver");
			BehaviourComp.OnCloseToTarget.AddUFunction(this, n"ReportCombat");
		}
	}

	void UnbindDelegates(AHazeActor Enemy)
	{
		ULarvaBehaviourComponent BehaviourComp = ULarvaBehaviourComponent::Get(Enemy);
		if (BehaviourComp != nullptr)
		{
			BehaviourComp.OnJustHatched.Unbind(this, n"ReportThreat");
			BehaviourComp.OnDisabled.Unbind(this, n"ReportThreatOver");
			BehaviourComp.OnCloseToTarget.Unbind(this, n"ReportCombat");
		}
	}

	bool IsValidThreat(AHazeActor Enemy)
	{
		ULarvaBehaviourComponent BehaviourComp = ULarvaBehaviourComponent::Get(Enemy);
		if (BehaviourComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void ShowDebugInfo()
	{
		FString Info;
		Info += "Larva music team\n";
		Info += "  Threats:\n";
		for (AHazeActor Threat : Threats)
		{
			Info += "    " + Threat.GetName() + "\n";
		}	
		Info += "  Combatants:\n";
		for (AHazeActor Combatant : Combatants)
		{
			Info += "    " + Combatant.GetName() + "\n";
		}	
		PrintScaled(Info);
	}
}

namespace LarvaMusicIntensity
{
	UFUNCTION()
	void SetLarvaInitialMusicIntensity(EMusicIntensityLevel Intensity, float AmbientDelay)
	{
		ULarvaMusicTeam Team = Cast<ULarvaMusicTeam>(HazeAIBlueprintHelper::GetTeam(n"LarvaMusicIntensityTeam"));
		if (Team != nullptr)
		{
			// Force team to set given intensity. Will last until team decides to set or clear intensity by itself.
			Team.SetInitialIntensity(Intensity, AmbientDelay);
		}
	}
}
