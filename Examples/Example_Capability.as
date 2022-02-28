/*
    This is a generic example capability showing what functions you can override
*/

namespace ExampleAttribueNamespace
{
	const FName ExampleAttributeName = n"HelloImAExample";
}

namespace ExampleActionsNamespace
{
	const FName ExampleActionName = n"HelloImDoingTheActionExample";
}

class ExampleCapability : UHazeCapability
{
    // Tags defines what "categories" the capbility belongs to, when this tag is blocked then the capability will be blocked
	default CapabilityTags.Add(n"Example");
	
	// Standard Tags:

	/* CapabilityTags::Movement
	 * All capabilites that moves the owning actor should have this tag
	*/

	/* CapabilityTags::MovementAction
	 * Movement capabilities that reacts to something 
	 * (pressing a button, hitting a wall, etc) should have this tag
	*/

	/* CapabilityTags::Input
	 * All capabilites that responde to input should have this tag
	*/

	/* CapabilityTags::StickInput
	 * All movement capabilites that responde to stick input should have this tag
	*/

	/* CapabilityTags::MovementInput
	 * All movement capabilites that responde to input should have this tag
	*/

	/* CapabilityTags::GameplayAction
	 * All movement capabilites that responde to action inputs
	 (jumping, shooting, etc) should have this tag
	*/

	/* CapabilityTags::CancelAction
	 * All capabilities that responde to the cancel input should have this tag
	*/


	// Capabilites are ticked in order of a tick group, 	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	/* The tickgroups are tick from top to bottom.
	* Every unreal tick group is ticked on this actor, then the next actor and so on.

	- UNREAL PrePhysics
		* ECapabilityTickGroups::Input,
		* ECapabilityTickGroups::BeforeMovement,
		* ECapabilityTickGroups::ReactionMovement,
		* ECapabilityTickGroups::ActionMovement,
		* ECapabilityTickGroups::LastMovement,

	- UNREAL Gameplay
		* ECapabilityTickGroups::BeforeGamePlay,
		* ECapabilityTickGroups::GamePlay,
		* ECapabilityTickGroups::AfterGamePlay,

	- UNREAL PostPhysics
		* ECapabilityTickGroups::AfterPhysics,

	- UNREAL PostUpdateWork
		* ECapabilityTickGroups::PostWork,

	- UNREAL End Of Frame
		* ECapabilityTickGroups::LastDemotable,
	*/


	// Internal tick order for the TickGroup, Lowest ticks first.
	default TickGroupOrder = 100;

	UHazeCharacterSkeletalMeshComponent CharacterMesh;
	UHazeCapabilityComponent CapabilityComponent;

    bool bIHaveANiceHat = false;

    /* Setup is called once, when the capability is created.
	* Good for setting up variables like pointers to components
	* For example, the 'CharacterMesh' can now be accessed in all the other capability functions
	*/
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        CharacterMesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		CapabilityComponent = UHazeCapabilityComponent::Get(Owner);
	}

    /* Checks if the Capability should be active and ticking
    * Will be called every tick when the capability is not active. will tick the same frame as ActiveLocal or ActivateFromControl is called
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        /* ActiveLocal
        *  Will active the capability locally regardless if it has control or not.
        *  If you want to return ActivateLocal then you should either make sure it is returned on both sides
        *  or the capability only does networks safe things (e.g. spawning particles)
		*/
		if(bIHaveANiceHat)
			return EHazeNetworkActivation::ActivateLocal;

        /* DontActivate
        * The capability will be skipped this frame and ShouldActivate will run again next tick.
		*/
		return EHazeNetworkActivation::DontActivate;
	}

    /* Checks if the Capability should deactivate and stop ticking
    *  Will be called every tick when the capability is activate and before it ticks. The Capability will not tick the same frame as DeactivateLocal or DeactivateFromControl is returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        /* DeactivateLocal
        *  Will deactivate the capability locally regardless if it has control or not.
        *  If you want to return DeactivateLocal then you should either make sure it is returned on both sides
        *  or the capability only does networks safe things (e.g. spawning particles)
		*/
		if(CheckIfShouldDeactive())
			return EHazeNetworkDeactivation::DeactivateLocal;

        /* DontDeactivate
        *  The capability will tick this frame and ShouldDeactivate will run again next tick.
		*/
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    bool CheckIfShouldDeactive() const
    {
        return false;
    }

    /* Called when the capability is activated, If called when activated by ActivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// This capability will block the tag that it has in itself.
		SetMutuallyExclusive(n"Example", true);

		// You can also block other capability tags.
		Owner.BlockCapabilities(n"GroundMovement", this);
	}

    /* Called when the capability is deactivated, If called when deactivated by DeactivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Don't forget to unblock the tag when the capability is deactivated
		SetMutuallyExclusive(n"Example", false);

		// Same here, don't forget to unblock it.
		Owner.UnblockCapabilities(n"GroundMovement", this);
	}

	/* Called when the capability is removed from its owner */
	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{}

	/* 	Runs every frame before the capability checks if it should be active or not, and before the TickActive.
		Can be used for timers and other mechanics that turns on and of the capability.
	*/
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{}

    /* Runs every frame the capability is active, can wary widely between remote and control
    *  If the control quickly activates and deactivate then tick might never run on the remote
	*/
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		/* This function will be TRUE when this capabilty is selected in the debug menu */
		if(IsDebugActive())
		{}

		/* 	Actions are values with tags that is fed into the owning capability component.
		* 	You can use FNames directly to get and set the values. But it is better define global variables instead to make sure the same FName is used in all cases.
		* 	Actions can be fed manually (ex AI behaviour tree) or from an external system (ex Player Input)
		*
		* 	Actions are either Active or not active, but you can think of them as having 4 states
		*	Activated
		*	Inactive
		*	Activated this frame
		*	Deactivated this frame
		*/

		if(WasActionStarted(ExampleActionsNamespace::ExampleActionName))
		{
			// Only valid the frame it went from inactive to active
		}

		if(WasActionStopped(ExampleActionsNamespace::ExampleActionName))
		{
			// Only valid the frame it went from active to inactive
		}

		if(IsActioning(ExampleActionsNamespace::ExampleActionName))
		{
			// Valid all the frames it is active
		}

		if (WasActioning(ExampleActionsNamespace::ExampleActionName, 5.f))
		{
			// Valid if action went from active to inactive at any time in the last 5 seconds.
		}

		if (WasActionStartedDuringTime(ExampleActionsNamespace::ExampleActionName, 5.f))
		{
			// Valid if action went from inactive to active at any time in the last 5 seconds.
		}

		if (WasActionActiveDuringTime(ExampleActionsNamespace::ExampleActionName, 5.f))
		{
			// Valid if action has been active for the last 5 seconds i.e. is active and have never been inactive during this time
		}

		// If active, this is how many seconds the action has been active as of now. If inactive, this is how long the last active period was. 
		float LastActiveDuration = GetLastActionDuration(ExampleActionsNamespace::ExampleActionName);

		/* You can get Attribute values aswell
		* But you have to be aware in what type the Attribute is created with.
		* The float and Vector Attribute are created seperately and have their own entries, but some of the vector values use the same values that are in the float attributes
		*/
		
		// This is how you set attributes
		Owner.SetCapabilityActionState(ExampleActionsNamespace::ExampleActionName, EHazeActionState::Active);
		Owner.SetCapabilityAttributeValue(ExampleAttribueNamespace::ExampleAttributeName, 4.5f);
		Owner.SetCapabilityAttributeVector(AttributeVectorNames::LeftStickRaw, FVector::ZeroVector);

		// You can also use custom names
		UObject TestObject = Owner;
		Owner.SetCapabilityAttributeObject(n"HelloImAttributeObject", TestObject);
		Owner.SetCapabilityAttributeNumber(n"HelloImAttribute", 4);

		//Will return 0.f if the attribute has not been set.
		float ExampleAttributeFloatValue = GetAttributeValue(ExampleActionsNamespace::ExampleActionName);
		//Will return a ZeroVector if the attribute has not been set.
		FVector ExampleAttributeVectorValue = GetAttributeVector(AttributeVectorNames::LeftStickRaw);

		/* 	The GetAttributeVector2D returns the same values as GetAttributeVector but in 2D space.
		* 	Meaning Forward in 3Dspace(X-Axis) is now up in 2DSpace(Y-Axis) and Right in 3DSpace(Y-Axis) is now Right in 2DSpace(X-Axis)
		*/
		FVector2D ExampleAttributeVector2DValue = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		int ExampleValidatedNumber = -1;
		if (ConsumeAttribute(n"HelloImAttribute", ExampleValidatedNumber))
		{
			//True if the attribute has been set.
			// The value will be cleared when calling this function
		}
		else
		{
			//Attribute has not been set. ExampleValidatedNumber will still be -1 in this case
		}

		if (WasAttributeValueChangedDuringTime(ExampleActionsNamespace::ExampleActionName, 5.f) ||
			WasAttributeVectorChangedDuringTime(AttributeVectorNames::LeftStickRaw, 5.f) ||
			WasAttributeObjectChangedDuringTime(n"HelloImAttributeObject", 5.f) ||
			WasAttributeNumberChangedDuringTime(n"HelloImAttribute", 5.f))
		{
			// Valid if given attribute has changed during the given time in seconds. There are separate functions for different types of attributes as seen above
		}

		if (WasAttributeValueZeroDuringTime(ExampleActionsNamespace::ExampleActionName, 5.f) ||
			WasAttributeVectorZeroDuringTime(AttributeVectorNames::LeftStickRaw, 5.f))
		{
			// Convenience functions to check if attribute value is zero and hasn't been changed in given duration
		}
	}

	// Called when any of the tags in the capability gets blocked
	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{

	}

	// Called when any of the tags in the capability gets unblocked
	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}
	
    /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FVector TempVec = FVector(400.f, 10.f, 0.f);

		FString Str = "Example string that will show in the capability debug menu";

		// Clean up float
		float DebugValue = 32.303232131;
		Str += TrimFloatValue(DebugValue);

		// New line
		Str += "\n";
		
		// It is valid to Tag text with color tags as well
		Str += "Velocity: <Yellow>" + TempVec + "</>";

		// Vectors can return individual color on its internal values
		Str += "Velocity with color: " + TempVec.ToColorString();

        return Str;
	}
};