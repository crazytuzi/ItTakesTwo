UCLASS(Meta = (ComposeSettingsOnto = "ULarvaComposableSettings"))
class ULarvaComposableSettings : UHazeComposableSettings
{
	// How far away larva will be able to detect enemies
    UPROPERTY(Category = "LarvaBehaviour|Perception")
    float MaxTargetDistance = 2000.f;

	// How far away in 2D space larva will attempt to drop onto target if above. This is scaled so that we have max drop radius when upside down in world space.
    UPROPERTY(Category = "LarvaBehaviour|Pursue")
    float DropRadius = 800.f;

	// How high above target larva must be to consider dropping
    UPROPERTY(Category = "LarvaBehaviour|Pursue")
    float DropHeight = 300.f;

	// How high above target floor height larva will start to climb sideways across obstacles instead of only over them.
    UPROPERTY(Category = "LarvaBehaviour|Pursue")
    float OverTopMaxHeight = 400.f;

	// How far away larva will start exploding leap
    UPROPERTY(Category = "LarvaBehaviour|Attack")
    float AttackDistance = 300.f;

	// Larva will stop to eat any sap within this distance from it's mouth 
    UPROPERTY(Category = "LarvaBehaviour|Eat")
	float EatRadius = 60.f;

	// How many seconds larva takes to consume one unit of sap
    UPROPERTY(Category = "LarvaBehaviour|Eat")
    float EatSapDuration = 0.5f;

	// When we've eaten this much sap we will explode from a match hit
	UPROPERTY(Category = "LarvaBehaviour|Eat")
	float EatenSapExplosiveAmount = 3.f;

	// If sap explodes within thius radius from larva, it will die
    UPROPERTY(Category = "LarvaBehaviour|Health")
	float ExplodingSapDeathRadius = 300.f;

	// Should larva explode when hit by match?
    UPROPERTY(Category = "LarvaBehaviour|Health")
	bool bExplodesFromMatch = false;

	// Top speed when crawling
    UPROPERTY(Category = "LarvaBehaviour|Repulsion")
	float CrawlSpeed = 400.f;

	// Within this distance outside of collision radius larva will try to stay away from each other
    UPROPERTY(Category = "LarvaBehaviour|Repulsion")
	float RepulseDistance = 250.f;

	// Max speed at which we push away from other larvae when very near each other
    UPROPERTY(Category = "LarvaBehaviour|Repulsion")
	float RepulseSpeed = 400.f;
}

