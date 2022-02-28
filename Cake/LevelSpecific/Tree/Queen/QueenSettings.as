
import Peanuts.Health.BossHealthBarWidget;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourSettingsContainer;

UCLASS(meta = (ComposeSettingsOnto = "UQueenSettings"))
class UQueenSettings : UHazeComposableSettings
{
	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FQueenSwarmBuilderSettings Builder;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FQueenSwarmAbilities Abilities;
};

USTRUCT(Meta = (ComposedStruct))
struct FQueenSwarmBuilderSettings
{

 	// How fast the swarm is built - when we have _0_ swarms active. Unit: Seconds. '-1' means don't build at all.
  	UPROPERTY(Category = "Builder")
	float BuildTime_Zero = -1.f;

 	// How fast the swarm is built - when we have _1_ swarms active. Unit: Seconds. '-1' means don't build at all.
  	UPROPERTY(Category = "Builder")
	float BuildTime_Solo = -1.f;

 	// How fast the swarm is built - when we have _2_ swarms active. Unit: Seconds. '-1' means don't build at all.
  	UPROPERTY(Category = "Builder")
	float BuildTime_Duo  = -1.f;

 	// How fast the swarm is built - when we have _3_ swarms active. Unit: Seconds. '-1' means don't build at all.
  	UPROPERTY(Category = "Builder")
	float BuildTime_Trio = -1.f;

 	// How fast the swarm is built - when we have _4_ swarms active. Unit: Seconds. '-1' means don't build at all.
  	UPROPERTY(Category = "Builder")
	float BuildTime_Quad = -1.f;

	float GetBuildTime(int NumSwarmsActive) const
	{
		switch (NumSwarmsActive)
		{
		case 0:
			return BuildTime_Zero;
		case 1:
			return BuildTime_Solo;
		case 2:
			return BuildTime_Duo;
		case 3:
			return BuildTime_Trio;
		case 4:
			return BuildTime_Quad;
		}

		ensure(false);
		return -1;
	}

}

USTRUCT(Meta = (ComposedStruct))
struct FQueenSwarmAbilities
{
	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle HandSmash_Left;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle HandSmash_Right;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle Shield;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle Tornado;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle Hammer;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle Sword;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle RailSword;

	UPROPERTY(Category = "Swarm Abilities")
	FSwarmSettingsBundle GrabSpline;
}

struct FSwarmSettingsBundle
{
 	UPROPERTY()
	UHazeCapabilitySheet SwarmSheet;

 	UPROPERTY()
	USwarmBehaviourBaseSettings SwarmSettings;
};


