import Cake.LevelSpecific.Tree.Wasps.WaspTypes;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;

// Wasp trigger base which does not rely on overlaps, for performance sake
class AWaspDeathTrigger : AHazeActor
{
	// Don't tick that often, it's no biggie if wasp does not die immediately, or tunnels through
	default ActorTickInterval = 0.2f;

	// No need for this to do anything when players are distant (as currently used)
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	int WaspIndex = 0;
	UBoxComponent TriggerBox = nullptr;
	float DefaultTickInterval = 0.2f;

	// Rather annoying that teams don't use an array, let's fix that for next project 
	TArray<AHazeActor> Wasps;
	UHazeAITeam WaspTeam = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerBox = UBoxComponent::Get(this); 
		if (TriggerBox == nullptr)
			SetActorTickEnabled(false);
		DefaultTickInterval = ActorTickInterval;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Start checking wasps if there's a wasp team
		UpdateWaspTeam();
		if ((WaspTeam == nullptr) || (WaspTeam.GetNumberOfMembers() == 0))
		{
			// No need to tick until there are any wasps
			SetActorTickInterval(2.f);
			return;
		}
		if (ActorTickInterval > DefaultTickInterval)
			SetActorTickInterval(DefaultTickInterval);

		// Check overlap for one wasp each tick	
		for (int i = 0; i < Wasps.Num(); i++)
		{
			int iWasp = (WaspIndex + i) % Wasps.Num();
			AHazeActor Wasp = Wasps[iWasp];
			if (!System::IsValid(Wasp) || Wasp.IsActorDisabled())
				continue;
			
			// Found valid wasp, check if overlapping
			FVector LocalAbsLoc = TriggerBox.WorldTransform.InverseTransformPosition(Wasp.ActorLocation).GetAbs();
			if ((LocalAbsLoc.X < TriggerBox.BoxExtent.X) && (LocalAbsLoc.Y < TriggerBox.BoxExtent.Y) && (LocalAbsLoc.Z < TriggerBox.BoxExtent.Z))
			{
				UWaspHealthComponent WaspHealth = UWaspHealthComponent::Get(Wasp);
				if (WaspHealth != nullptr)
					WaspHealth.Die();
			}			 
			WaspIndex = iWasp + 1;
			break;
		}
	}

	void UpdateWaspTeam()
	{
		UHazeAITeam Team = HazeAIBlueprintHelper::GetTeam(Wasp::TeamName);
		if (Team != WaspTeam)
		{
			WaspTeam = Team;
			if (Team != nullptr)
				UpdateTeamMembers();
		}
		else if ((WaspTeam != nullptr) && (WaspTeam.GetNumberOfMembers() != Wasps.Num()))
		{
			UpdateTeamMembers();
		}
	}

	void UpdateTeamMembers()
	{
		Wasps.Empty(WaspTeam.GetNumberOfMembers());
		for (AHazeActor Wasp : WaspTeam.GetMembers())
		{
			Wasps.Add(Wasp);
		}
	}
}