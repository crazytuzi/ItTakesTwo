/*
    This is a generic example capability showing what functions you can override for networking
*/


class ExampleNetworkCapability : UHazeCapability
{
	bool ExampleCanActiveFunction()const
	{
		/* The world has control in this side */
		if(Network::HasWorldControl())
		{
			return false;
		}

		/* The owner has control on this side */
		if(HasControl())
		{
			return false;
		}

		return false;
	}
   
    /* Checks if the Capability should be active and ticking
    * Will be called every tick when the capability is not active. will tick the same frame as ActiveLocal or ActivateFromControl is called
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        /* ActivateFromControl
        * Will activate on the side where the Owner/Capability has control.
        * The control side will then send a message to the remote where the capability will then be activated
		* 1. Calls 'ControlPreActivation' before sending the activation request.
		* 2. Calls 'RemoteAllowShouldActivate' before activating on the remote side.
		* If 'RemoteAllowShouldActivate' is valid:
		* 	If Active:   calls 'OnDeactivated' | 'OnActivated'.
		* 	If Deactive: calls 'OnActivated'
		* 	If Blocked:  calls 'OnActivated' (Stale) | 'OnDeactivated' (Stale)
		*/
		if(ExampleCanActiveFunction())
        	return EHazeNetworkActivation::ActivateFromControl;


        /* ActivateFromControlWithValidation
		* Will put the control side in an idle state until the response it received.
		* 1. Calls 'ControlPreActivation' before sending the activation request.
		* 2. Calls 'RemoteAllowShouldActivate' on the remote side and sends back the answer.
		* (If the remote side is blocked or active, it will return false whithout validating)
		* 3. If the validation is valid, it will activate on the remote side
		* 4. When the response comes back to the control side, it will call ControlPostValidation with the FWaspResponseAnimSet
		* 5. If the validation is valid, it will activate on the control side
		*/
		if(ExampleCanActiveFunction())
        	return EHazeNetworkActivation::ActivateFromControlWithValidation;
	

		/* ActivateUsingCrumb
		* Will activate on the control side and leave a network crumb on the remote side.
		* 1. Calls 'ControlPreActivation' before sending the crumb
		* 	If Deactive and the crumb is next in line:
		* 	2. Calls 'RemoteAllowShouldActivate'
		* 	3. If 'RemoteAllowShouldActivate' is valid:
		*		Crumb: 'OnActivated'
		*		Stale crumb: 'OnActivated' (Stale)
		*/
		if(ExampleCanActiveFunction())
       		return EHazeNetworkActivation::ActivateUsingCrumb;
			

		return EHazeNetworkActivation::DontActivate;
	}


    /* Checks if the Capability should deactivate and stop ticking
    *  Will be called every tick when the capability is activate and before it ticks. The Capability will not tick the same frame as DeactivateLocal or DeactivateFromControl is returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		/* DeactivateFromControl
        * Will deactivate on the side where the Owner/Capability has control.
        * The control side will then send a message to the remote where the capability will then be deactivated
		* 1. Calls 'ControlPreDeactivation(' before sending the deactivation request.
		* 2. Calls 'RemoteAllowShouldDeactivate'
		* 3. If 'RemoteAllowShouldDeactivate' is valid:
		*    If Active: Calls 'OnDeactivated'
		*    If Blocked or Deactive: Nothing happens, deactivate is ignored
		*/
		if(ExampleCanActiveFunction())
			return EHazeNetworkDeactivation::DeactivateFromControl;


        /* DeactivateUsingCrumb
		* Will deactivate on the control side and leave a network crumb on the remote side.
		* 1. Calls 'ControlPreDeactivation(' before sending the deactivation request.
		* 2. Calls 'RemoteAllowShouldDeactivate'
		* 3. If 'RemoteAllowShouldDeactivate' is valid:
		*    If Active: Calls 'OnDeactivated'
		*    If Active and Stale Crumb: Calls 'OnDeactivated' (Stale)
		*    If Blocked or Deactive: Nothing happens, deactivate is ignored
		*/
		if(ExampleCanActiveFunction())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DeactivateLocal;

	}

	/* The remote side can't activate a control activation until this function returns true */
	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	/* The remote side can't deactivate a control deactivation until this function returns true */
	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldDeactivate() const
	{
		return true;
	}


	float ExmampleValue = 0;
	UFUNCTION(NetFunction)
	void NetExampleFunction(float Value)
	{
		ExmampleValue = Value;
	}

    /* 
    * This function is only triggered on the control side if a non local activation type is used.
	* you can use this for sending over data to the other side.
	*/
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		/* If you want the actor to sync up the transform on the other side when activating with a control function 
		* OBS! Crumbs activation already have this option on by default
		*/
		ActivationParams.EnableTransformSynchronizationWithTime();

		/* If you don't want the actor to sync up the transform on the other side when activating with a control function 
		* OBS! Control activation already have this option disabled by default
		*/
		ActivationParams.DisableTransformSynchronization();

		NetExampleFunction(FMath::RandRange(0.f, 100.f));

		ActivationParams.AddActionState(n"TestAction");
		ActivationParams.AddNumber(n"TestNumber", 1);
		ActivationParams.AddObject(n"TestObject", nullptr);
		ActivationParams.AddValue(n"TestValue", 20.f);
		ActivationParams.AddVector(n"TestVector", FVector::ZeroVector);
	}

    /* 
    * This function is only triggered on the control if the activation type is 'ActivateFromControlWithValidation'
	*/
	UFUNCTION(BlueprintOverride)
	void ControlPostValidation(bool bWasValid)
	{

	}

    /* 
    * This function is only triggered on the control side if a non local deactivation type is used.
	* you can use this for sending over data to the other side.
	*/
	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		/* If you want the actor to sync up the transform on the other side when deactivating with a control function 
		*/
		DeactivationParams.EnableTransformSynchronizationWithTime();

		/* If you don't want the actor to sync up the transform on the other side when activating with a control function 
		* OBS! Control and Crumb deactivation already have this option disabled by default
		*/
		DeactivationParams.DisableTransformSynchronization();

		DeactivationParams.AddActionState(n"TestAction");
		// and so on...
	}



	/* This will trigger when 'TriggerNotification' is called on the control side.
	* Triggers on the remote side if:
	* 1. The remote side is on the same activation count
	* 2. The remote side is still active
	* 3.1. The current active time is equal or greater the the activation time of the notification if the activation was made using control activation.
	* 3.2. The current crumb is the notification crumb if the activation was made using crumb activation.
	* If the activation count is lower then expected, it will store the notification until we reach the same count.
	* The NotificationParams will be stale if capability has been deactivated or the crumb was stale
	*/
	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == n"TestNotification")
		{

		}
		else if(Notification == n"TestNotification_WithParams")
		{

		}
	}
	
   
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		/* This will send the notificaiton to both control and remote side 
		 * Calls the 'NotificationReceived'
		*/
		TriggerNotification(n"TestNotification");

		FCapabilityNotificationSendParams NotificationParams;
		TriggerNotification(n"TestNotification_WithParams", NotificationParams);

		/* This is how you read values from the activation params */		
		bool ActionState = ActivationParams.GetActionState(n"TestAction");
		float Value = ActivationParams.GetValue(n"UnfoundValue");
		FVector Vector = ActivationParams.GetVector(n"UnfoundVector");
		UObject Object = ActivationParams.GetObject(n"UnfoundObject");
		int Number = ActivationParams.GetNumber(n"UnfoundNumber");
	}

    /* Called when the capability is deactivated, If called when deactivated by DeactivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}
};