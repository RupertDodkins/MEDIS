import numpy as np
import ipdb
import pprint


class PID:
    """
    Discrete PID control
    """

    def __init__(self, P=0.3,
                       I=0.1,
                       D=0.0,
                       Derivator=0, 
                       Integrator=0, 
                       Integrator_max=0.1, 
                       Integrator_min=-0.1,
                       Deadband = 0.0):

        self.Kp=P
        self.Ki=I
        self.Kd=D
        self.Derivator=Derivator
        self.Integrator=Integrator
        self.Integrator_max=Integrator_max
        self.Integrator_min=Integrator_min
        
        self.deadband = Deadband
        self.set_point=0.0
        self.error=0.0

    def update(self,current_value):
        """
        Calculate PID output value for given reference input and feedback
        """
        self.error = self.set_point - current_value
        
        if self.deadband !=0:
            if np.size(self.error)==1:
                if np.abs(self.error)<self.deadband:
                    self.error = 0
                else:
                    if self.error<0:
                        self.error = self.error +self.deadband
                    else:
                        self.error = self.error - self.deadband
            
            if np.size(self.error)>1:
                 zeroinds=np.where(np.abs(self.error)<self.deadband)
                 plusinds=np.where(self.error>self.deadband)
                 minusinds=np.where(self.error<-self.deadband)
                 self.error[zeroinds]=0
                 self.error[plusinds]=self.error-self.deadband
                 self.error[minusinds]=self.error+self.deadband
                
                

        self.P_value = self.Kp * self.error
        self.D_value = self.Kd * ( self.error - self.Derivator)
        self.Derivator = self.error

        self.Integrator = self.Integrator + self.error

        if np.any(self.Integrator > self.Integrator_max):
            self.Integrator = self.Integrator_max
        elif np.any(self.Integrator < self.Integrator_min):
            self.Integrator = self.Integrator_min

        self.I_value = self.Integrator * self.Ki

        PID = self.P_value + self.I_value + self.D_value

        return PID

    def setPoint(self,set_point):
        """
        Initilize the setpoint of PID
        """
        self.set_point = set_point
        self.Integrator=0
        self.Derivator=0

    def setIntegrator(self, Integrator):
        self.Integrator = Integrator

    def setDerivator(self, Derivator):
        self.Derivator = Derivator
    
    def setDeadband(self, Deadband):
        self.Deadband=Deadband

    def setKp(self,P):
        self.Kp=P
    
    def setKi(self,I):
        self.Ki=I

    def setKd(self,D):
        self.Kd=D

    def getPoint(self):
        return self.set_point

    def getError(self):
        return self.error

    def getIntegrator(self):
        return self.Integrator

    def getDerivator(self):
        return self.Derivator

if __name__ == "__main__":
    p=PID(P=np.array([0.5,0.5]),
          I=np.array([0.2, 0.2]),
          D=np.array([0, 0]))
    p.setPoint(np.array([5.0, 5.0]))
    while True:
        valx=float(raw_input("enter a positionx: "))
        valy=float(raw_input("enter a positiony: "))
        val=np.array([valx, valy])
        pid=p.update(val)
        pprint.pprint( pid)
        #pprint.pprint (p.__dict__)



